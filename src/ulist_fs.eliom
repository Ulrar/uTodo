open Tools
open Services
open%shared Ulist_t
open%shared Ulist_j

let%server cache : (string, Ulist_t.ulist option) Eliom_cscache.t =
  Eliom_cscache.create ()

let%server readUList path =
  let%lwt exists = Lwt_unix.file_exists path in
  if exists
  then
    let%lwt f = Lwt_io.open_file Lwt_io.Input path in
    let s = Lwt_io.read_lines f in
    let%lwt res = Lwt_stream.fold (^) s "" in
    try let ulist = Ulist_j.ulist_of_string res in
      Lwt.return (Some ulist)
    with
      _ -> Lwt.return (Some {emails = []; tasks = []})
  else
    Lwt.return None

let%server readUList_rpc =
  Eliom_client.server_function [%derive.json: string] readUList

let%client readUList path = ~%readUList_rpc path

let%shared getUList category name =
  let path = "lists/" ^ category ^ "/" ^ name in
  Eliom_cscache.find ~%cache readUList path

let writeUList category name l =
  let path = "lists/" ^ category ^ "/" ^ name in
  let%lwt f = Lwt_io.open_file Lwt_io.Output path in
  Lwt_io.write f (Ulist_j.string_of_ulist l)

let%shared rec func x lst c = match lst with
    | [] -> raise Not_found
    | hd::tl -> if (hd.uuid = x) then c else func x tl (c + 1)

let%shared find x lst = func x lst 0

let%server saveTask (category, listName, nUuid, nSubList, nLabel, nStatus) =
  let%lwt maybeL = getUList category listName in
  match maybeL with
  | None -> Lwt.return None
  | Some l -> (* Updating existing task *)
    try let n = find nUuid l.tasks in
      let tasks' = List.mapi (fun i x ->
        if i = n
        then
          {uuid = nUuid; subList = nSubList; label = nLabel; status = nStatus}
        else
          x
        ) l.tasks
      in
      let l' = {emails = l.emails; tasks = tasks'} in
      let%lwt _ = writeUList category listName l' in
      Lwt.return (Some l')
    with Not_found -> (* Adding new task *)
      let tasks' = List.append l.tasks
        [{uuid = nUuid; subList = nSubList; label = nLabel; status = nStatus}]
      in
      let l' = ({emails = l.emails; tasks = tasks'}) in
      let%lwt _ = writeUList category listName l' in
      Lwt.return (Some l')

let%server deleteTask (category, listName, id) =
  let%lwt maybeL = getUList category listName in
  match maybeL with
  | None -> Lwt.return None
  | Some l ->
    let tasks' = List.filter
      (fun x -> if x.uuid <> id then true else false) l.tasks
    in
    let l' = ({emails = l.emails; tasks = tasks'}) in
    let%lwt _ = writeUList category listName l' in
    Lwt.return (Some (l', l))

open%shared Tools
open%shared Ulist_t
open%shared Ulist_fs

(* Separate implementations for splitLabel, module Str doesn't work on client *)
(* side, so we use Regexp instead (which doesn't exist on server side)        *)
[%%server
  let splitLabel lbl = Str.split (Str.regexp "/+") lbl
]

[%%client
  let splitLabel lbl = Regexp.split (Regexp.regexp "/") lbl

  let serverSaveTask =
    ~%(Eliom_client.server_function
      [%derive.json: string * string * string * bool * string * bool]
       Ulist_fs.saveTask)

  let saveTask (rt, rh) category listName nUuid nSubList nLabel nStatus =
    let%lwt l = serverSaveTask
      (category, listName, nUuid, nSubList, nLabel, nStatus)
    in
    let path = ("lists/" ^ category ^ "/" ^ listName) in
    let _ = Eliom_cscache.do_cache ~%Ulist_fs.cache path l in
    let%lwt nlist = Ulist_fs.getUList category listName in
    match l with
    | None -> Lwt.return ()
    | Some l' ->
      let pos = findTask nUuid l'.tasks in
      let elem = List.nth l'.tasks pos in
      Eliom_shared.ReactiveData.RList.update (false, elem) pos rh;
      Lwt.return ()

  let serverDeleteTask =
    ~%(Eliom_client.server_function
      [%derive.json: string * string * string] Ulist_fs.deleteTask)

  let deleteTask (rtasks, rhandle) category listName id =
    let%lwt maybeL = serverDeleteTask (category, listName, id) in
    let path = ("lists/" ^ category ^ "/" ^ listName) in
    match maybeL with
    | None -> Lwt.return ()
    | Some (l, old) ->
      let pos = findTask id old.tasks in
      Eliom_cscache.do_cache ~%Ulist_fs.cache path (Some l);
      Eliom_shared.ReactiveData.RList.remove pos rhandle;
      Lwt.return ()

(* %%client *)]

[%%shared
  let genEditBtn
    (t : Ulist_t.task)
    ((rt, rh) : (bool * Ulist_j.task) Eliom_shared.ReactiveData.RList.t *
                (bool * Ulist_j.task) Eliom_shared.ReactiveData.RList.handle) =
    let switchToEdit = [%client
      (fun _ ->
        let pos = findTask ~%t.uuid
          (List.map (fun (b, t) -> t)
          (Eliom_shared.ReactiveData.RList.value ~%rt))
        in
        Eliom_shared.ReactiveData.RList.update (true, ~%t) pos ~%rh)
    ] in
    let edit = Eliom_content.Html.D.(Raw.a
      ~a:[a_onclick switchToEdit; a_href (Raw.uri_of_string "#")]
      [img ~alt:("Edit") ~src:(make_uri ~service:(Eliom_service.static_dir ())
      ["images"; "edit.ico"]) ()])
    in
    edit

  let genDelBtn
    (category : string)
    (listName : string)
    (t : Ulist_t.task)
    (rtasks : (bool * Ulist_j.task) Eliom_shared.ReactiveData.RList.t *
              (bool * Ulist_j.task) Eliom_shared.ReactiveData.RList.handle) =
    let clientDeleteTask = [%client
      (fun _ -> ignore (deleteTask ~%rtasks ~%category ~%listName ~%t.uuid))]
    in
    let delete = Eliom_content.Html.D.(Raw.a
      ~a:[a_onclick clientDeleteTask; a_href (Raw.uri_of_string "#")]
      [img ~alt:("Delete")
      ~src:(make_uri ~service:(Eliom_service.static_dir ())
      ["images"; "delete.ico"]) ()])
    in
    delete

  let genNestedIcon (t : Ulist_t.task) =
    if t.subList
    then
      Eliom_content.Html.D.([img ~a:[a_class ["center-block"]] ~alt:("Nested")
        ~src:(make_uri ~service:(Eliom_service.static_dir ())
        ["images"; "arrow-openned.ico"]) ()])
    else
      []
]

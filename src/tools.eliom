open Services
open%shared Ulist_t

let rec buildDirectoryListing d res = 
  Lwt.catch (fun () ->
    let%lwt cur = Lwt_unix.readdir d in
    if cur <> "." && cur <> ".."
    then
      buildDirectoryListing d ([cur] @ res)
    else
      buildDirectoryListing d res)
  (fun _ ->
    let%lwt _ = Lwt_unix.closedir d in
    Lwt.return res)

let listDirectory path =
  let%lwt d = Lwt_unix.opendir path in
  buildDirectoryListing d []

[%%shared
let findTask x lst =
  let rec f x (lst : Ulist_t.task list) c = match lst with
    | [] -> raise Not_found
    | hd::tl -> if (hd.uuid = x) then c else f x tl (c + 1)
  in
  f x lst 0

let calcClassFromNL nl =
  if nl = 0
  then
    ("col-md-point5",
     "col-md-10")
  else
    let nlf = float_of_int nl in
    let v = int_of_float (ceil (nlf /. 2.0)) in
    if (nl mod 2) = 0
    then
      ("col-md-" ^ (string_of_int v) ^ "point5",
       "col-md-" ^ (string_of_int (10 - v)))
    else
      ("col-md-" ^ (string_of_int v)),
       "col-md-" ^ (string_of_int (10 - v) ^ "point5")

(* %%shared *)]

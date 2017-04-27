open Tools
open Services

let category_service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["category"])
    ~meth:(Eliom_service.Get Eliom_parameter.(suffix (string "category")))
    ()

let%lwt categories = listDirectory "lists"

let genLists cat =
  let%lwt lists = listDirectory ("lists/" ^ cat) in
  Lwt.return Eliom_content.Html.F.
  (
    div ~a:[a_class ["container-fluid"]]
      (List.map
        (fun (l) ->
          div ~a:[a_class ["row"; "row-hover"]]
            [div ~a:[a_class ["col-md-7"]] [a list_service [pcdata l] (cat, l)];
             div ~a:[a_class ["col-md-2"]] [pcdata "0%"]])
        lists)
  )

let createEmptyList (category, listName) =
  let%lwt l = Ulist_fs.getUList category listName in
  match l with
  | Some _ -> Lwt.return false (* List exists, do nothing *)
  | None   ->
    let path = "lists/" ^ category ^ "/" ^ listName in
    let%lwt f = Lwt_io.open_file Lwt_io.Output path in
    Lwt.return true

let%client createEmptyList_rpc =
  ~%(Eliom_client.server_function
       [%derive.json: string * string] createEmptyList)

let newListBtn (category : string) =
  let inpt = Eliom_content.Html.D.input () in
  let f = [%client
    (fun _ ->
       let elt = Eliom_content.Html.To_dom.of_input ~%inpt in
       let name = Js.to_string elt##.value in
       ignore (createEmptyList_rpc (~%category, name))
    )
  ] in
  let btn = Eliom_content.Html.D.(
    Raw.a
      ~a:[a_onclick f; a_href (Raw.uri_of_string "#")]
      [img ~alt:("Delete")
           ~src:(make_uri ~service:(Eliom_service.static_dir ())
                   ["images"; "delete.ico"]) ()])
  in
  Eliom_content.Html.D.
    (
      div ~a:[a_class ["row"; "row-hover"]]
        [
          div ~a:[a_class ["col-md-7"]] [inpt];
          div ~a:[a_class ["col-md-2"]] [btn]
        ]
    )

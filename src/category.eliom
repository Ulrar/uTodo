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

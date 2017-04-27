open Tools
open Services
open Category
open Menu
open Ulist

let () =
  Utodo_app.register
    ~service:main_service
    (fun () () ->
      template "index" [])

let () =
  Utodo_app.register
    ~service:category_service
    (fun category () ->
      let%lwt lists = genLists category in
      let newList = newListBtn category in
      template category Eliom_content.Html.F.
      (
        [h1 ~a:[a_class ["text-center"]] [pcdata category]; lists; newList])
      )

let () =
  Utodo_app.register
    ~service:list_service
    (fun (category, listName) () ->
      let%lwt l = Ulist_fs.getUList category listName in
      match l with
      | None -> template listName [Eliom_content.Html.F.pcdata "no such list"]
      | Some ulist ->
        let%lwt (content, btnNewTsk) = genTaskTable ulist category listName in
        template listName Eliom_content.Html.F.
                            ([
                              h1 ~a:[a_class ["text-center"]] [pcdata listName];
                              content;
                              btnNewTsk
                            ])
    )

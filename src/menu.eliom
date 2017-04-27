open Category
open Services

let genMenu () =
  Eliom_content.Html.F.
  (
    nav ~a:[a_class ["navbar"; "navbar-default"]]
      [ul ~a:[a_class ["nav"; "navbar-nav"]]
        ([li [a main_service [pcdata "home"] ()]] @
        (List.map (fun (str) -> li [a category_service [pcdata str] str])
          categories))]
  )

let template title bdy =
  Lwt.return
    (Eliom_tools.F.html
      ~title:title
      ~css:[["css";"bootstrap.min.css"];["css";"bootstrap-theme.min.css"]]
      Eliom_content.Html.F.(body ([genMenu ()] @ bdy)))

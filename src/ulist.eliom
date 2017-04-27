open Menu
open Category
open%shared Tools
open%shared Ulist_t
open%shared Ulist_j
open%shared Ulist_btn

[%%shared
  let taskEditModeToHtml nl rtasks category listName (editMode, t) =
    Eliom_content.Html.D.
    (
      let lbl = input ~a:[a_input_type `Text; a_value t.label] () in
      let saveEdit = [%client
        (fun _ ->
          let elt = Eliom_content.Html.To_dom.of_input ~%lbl in
          let lbl = Js.to_string elt##.value in
          let t = ~%t in
          let listName = ~%listName in
          let category = ~%category in
          let rtasks = ~%rtasks in
          ignore
            (saveTask rtasks category listName t.uuid t.subList lbl t.status)
        )
      ] in
      let confirm = Raw.a
        ~a:[a_onclick saveEdit; a_href (Raw.uri_of_string "#")]
        [img ~alt:("Confirm")
        ~src:(make_uri ~service:(Eliom_service.static_dir ())
        ["images"; "confirm.ico"]) ()]
      in
      let (cln, cll) = calcClassFromNL nl in
      div ~a:[a_class ["row"]]
      [
        div ~a:[a_class [cln]] [];
        div ~a:[a_class [cll]] [lbl];
        div ~a:[a_class ["col-md-1"]] [confirm]
      ]
    )

  let displayTask nl rtasks category listName (editMode, t) =
    Eliom_content.Html.D.
    (
      let checkbox = input ~a:([a_input_type `Checkbox] @
        (if t.status then [a_checked ()] else [])) () in
      let _ = [%client (Lwt.async (fun () ->
        let elt = Eliom_content.Html.To_dom.of_element ~%checkbox in
          Lwt_js_events.clicks elt (fun _ _ ->
            let t = ~%t in
            saveTask ~%rtasks ~%category ~%listName t.uuid t.subList t.label
              (Js.to_bool (Js.Unsafe.get elt "checked")))
      ) : unit)] in
      let ni = genNestedIcon t in
      let delete = genDelBtn category listName t rtasks in
      let edit = genEditBtn t rtasks in
      let (cln, cll) = calcClassFromNL nl in
      (* FIXME : The a_style is a dirty fix to "fix" rows inside rows *)
      let aclasses = ([a_class ["row"; "row-hover"]] @
        if t.subList then [a_style "margin: 0"] else [])
      in
      div ~a:aclasses
      [
        div ~a:[a_class [cln]] ni;
        div ~a:[a_class [cll]] [pcdata t.label];
        div ~a:[a_class ["col-md-point5"]] [checkbox];
        div ~a:[a_class ["col-md-1"]] [edit; pcdata " "; delete]
      ]
    )

  let subListToHtml cbuild nl rtasks category listName t =
    let spt = splitLabel t.label in
    let category' = (List.nth spt 0) in
    let listName' = (List.nth spt 1) in
    let%lwt l = Ulist_fs.getUList category' listName' in
    Eliom_content.Html.D.
    (
      match l with
      | None -> let (clc, cll) = calcClassFromNL (nl + 1) in
        Lwt.return (div ~a:[a_class ["row"]]
          [displayTask nl rtasks category listName (false, t);
           div ~a:[a_class [clc]] [];
           div ~a:[a_class [cll; "alert-danger"]] [pcdata "No such list"]])
      | Some ulist ->
        let et = List.map (fun t -> (false, t)) ulist.tasks in
        let rtasks' = Eliom_shared.ReactiveData.RList.create et in
        let%lwt content = cbuild (nl + 1) rtasks' category' listName' in
        let tab = div ~a:[a_class ["row"]] [div
          [
            displayTask nl rtasks category listName (false, t);
            Eliom_content.Html.R.div ~a:[a_class ["container-fluid"]] content
          ]
        ] in
        Lwt.return tab
    )

  let taskToHtml nl rtasks category listName displaySubList (editMode, t) =
    Eliom_content.Html.D.
    (
      if editMode
      then
        Lwt.return (taskEditModeToHtml nl rtasks category listName (editMode, t))
      else
        if t.subList
        then
          displaySubList nl rtasks category listName t
        else
          Lwt.return (displayTask nl rtasks category listName (editMode, t))
    )
]

(* Dirty workaround limitations of RList *)
(* FIXME: Think of something *)
[%%client
  let rec displaySubList nl rtasks category listName t =
    subListToHtml mapTasksR nl rtasks category listName t
  and mapTasksR nl rtasks category listName =
    Eliom_shared.ReactiveData.RList.Lwt.
    (
      let sf = (taskToHtml nl rtasks category listName displaySubList) in
      map_p sf (fst rtasks)
    )
]

[%%server
  let rec displaySubList nl rtasks category listName t =
    subListToHtml mapTasksR nl rtasks category listName t
  and mapTasksR nl rtasks category listName =
    Eliom_shared.ReactiveData.RList.Lwt.
    (
      let sf = [%shared
        (taskToHtml ~%nl ~%rtasks ~%category ~%listName displaySubList)]
      in
      map_p sf (fst rtasks)
    )
(* End dirty workaround *)

  let genTaskTable ulist category listName =
    Eliom_content.Html.D.
    (
        let et = List.map (fun t -> (false, t)) ulist.tasks in
        let rtasks = Eliom_shared.ReactiveData.RList.create et in
        let%lwt cnt = Eliom_shared.ReactiveData.RList.Lwt.map_p
          [%shared
            (taskToHtml 0 ~%rtasks ~%category ~%listName displaySubList)]
          (fst rtasks)
        in
        let addNewTask = [%client
        (fun _ -> Eliom_shared.ReactiveData.RList.snoc
          (true,
           {uuid  = (Uuidm.to_string (Uuidm.v `V4));
            subList = false;
            label = "";
            status = false
           }
          )
          (snd ~%rtasks)
        )
        ] in
        let btnNewTask = Eliom_content.Html.D.(div
          [Raw.a
             ~a:[a_onclick addNewTask; a_href (Raw.uri_of_string "#")]
             [img ~a:[a_class ["center-block"]] ~alt:("add")
                ~src:(make_uri ~service:(Eliom_service.static_dir ())
                        ["images"; "add.ico"]) ()]])
        in
      let tab = Eliom_content.Html.R.div ~a:[a_class ["container-fluid"]] cnt in
      Lwt.return (tab, btnNewTask)
    )
(* %%server *)]

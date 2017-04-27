module Utodo_app =
  Eliom_registration.App (
    struct
      let application_name = "utodo"
      let global_data_path = None
    end)

let main_service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

let list_service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["list"])
    ~meth:(Eliom_service.Get Eliom_parameter.(suffix (string "category" ** string "listName")))
    ()

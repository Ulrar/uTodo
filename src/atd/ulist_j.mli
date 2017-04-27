(* Auto-generated from "ulist.atd" *)


type task = Ulist_t.task = {
  uuid: string;
  subList: bool;
  label: string;
  status: bool
}

type ulist = Ulist_t.ulist = { emails: string list; tasks: task list }

val write_task :
  Bi_outbuf.t -> task -> unit
  (** Output a JSON value of type {!task}. *)

val string_of_task :
  ?len:int -> task -> string
  (** Serialize a value of type {!task}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_task :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> task
  (** Input JSON data of type {!task}. *)

val task_of_string :
  string -> task
  (** Deserialize JSON data of type {!task}. *)

val write_ulist :
  Bi_outbuf.t -> ulist -> unit
  (** Output a JSON value of type {!ulist}. *)

val string_of_ulist :
  ?len:int -> ulist -> string
  (** Serialize a value of type {!ulist}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_ulist :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> ulist
  (** Input JSON data of type {!ulist}. *)

val ulist_of_string :
  string -> ulist
  (** Deserialize JSON data of type {!ulist}. *)


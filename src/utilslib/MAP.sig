signature MAP = sig 
  type map
  type id = string
  type payload = string

  datatype fragment = Fragment of {
    offset : int,
    length : int,
    isLast : bool,
    fragPayload : payload
  }

  (* val lookup : id -> 'a t -> 'a frags option *)

  val add : id -> fragment -> map -> map

  val assemble : id -> map -> (payload * map) option

  (* Either do clean up on user side or in map *)

  val empty : unit -> map
end 

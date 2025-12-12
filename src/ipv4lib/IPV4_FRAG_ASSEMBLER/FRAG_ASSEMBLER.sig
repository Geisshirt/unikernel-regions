signature FRAG_ASSEMBLER = sig 
  type fragContainer
  type id = string
  type payload = string

  datatype fragment = Fragment of {
    offset : int,
    length : int,
    isLast : bool,
    fragPayload : payload
  }

  (* val lookup : id -> 'a t -> 'a frags option *)

  val add : id -> fragment -> fragContainer -> fragContainer

  val assemble : id -> fragContainer -> (payload * fragContainer) option

  val copy : fragContainer`r -> fragContainer`r'

  (* Either do clean up on user side or in map *)

  val empty : unit -> fragContainer
end 

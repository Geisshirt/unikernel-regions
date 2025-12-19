(*
    The FRAG_ASSEMBLER provides functionality for collecting, 
    managing, and assembling fragmented payloads identified by
    an id.
*)

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

  val add : id -> fragment -> fragContainer -> fragContainer

  val assemble : id -> fragContainer -> (payload * fragContainer) option

  val copy : fragContainer`r -> fragContainer`r'

  (* Either do clean up on user side or in map *)

  val empty : unit -> fragContainer
end 

(* 
  [fragment] Fragment represents a portion of a payload.
      - offset: starting position of the fragment in the payload.
      - length: length of the fragment
      - isLast: is it?
      - fragPayload: fragment payload as a string

  [add] Adds a fragment with the given id to the fragment container.

  [assemble] Attemps to assemble a payload for given id, returns SOME if all 
  fragments are present otherwise NONE.

  [copy] Creates a copy of the fragment container.

  [empty] Creates and returns an empty fragment container.
*)

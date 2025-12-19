(*
  The TRANSPORT_LAYER_HANDLER structure provides the interface for handling 
  the transport layer protocols of which currently are supported UDP and TCP. 
*)
signature TRANSPORT_LAYER_HANDLER = sig
  type h_context

  type info = {
    ownMac     : int list,
    dstMac     : int list,
    ownIPaddr  : int list,
    dstIPaddr  : int list,
    ipv4Header : IPv4Codec.header,
    payload : string
  }

  val copyContext : h_context`r -> h_context`r'

  val initContext : unit -> h_context`r

  val protocol_int : int

  val protocol_string : string

  val handl : info -> h_context -> h_context
end 

(*
  [info] Information passed from the IPv4 header.

  [copyContext] Creates a copy of the transport layer context.

  [initContext] Initializes and returns a fresh transport layer context.

  [protocol_int] IPv4 protocol digit associated with the this transport layer, 
  e.g. UDP = 17.

  [protocol_string] Human readable transport layer name e.g. "UDP".

  [handl] Handles incoming transport layer payloads and updates the 
  appropiate context.
*)
(*
  The TRANSPORT_LAYER structure provides a functionality for handling multiple
  transport layer protocols.
*)

signature TRANSPORT_LAYER = sig

  type context

  type protocol = int

  val protToString : protocol -> string

  datatype info = INFO of {
    ownMac     : int list,
    dstMac     : int list,
    ownIPaddr  : int list,
    dstIPaddr  : int list,
    ipv4Header : IPv4Codec.header,
    payload : string
  }

  val copyContext : context`r -> context`r'

  val initContext : unit -> context`r

  val resetContext : context -> unit

  val handl : protocol -> info -> context -> context

end

(* 
  [info] Information from the IPv4 header.

  [copyContext] Creates a copy of the transport layer context.

  [initContext] Initializes and returns a fresh transport layer context.

  [resetContext] Resets the given transport layer context to its initial state.

  [handl] Propagates the given payload to the appropriate transport layer 
  protocol handler based on the protocol, updating the shared context.
*)
(*
    The IPv4_HANDLE structure provides stateful handling of IPv4 packets.
*)

signature IPV4_HANDLE = sig
    type context

    val initContext : unit -> context

    val copyContext : context`r -> context`r'

    val handl   : {ownIPaddr : int list,
                   ownMac : int list, 
                   dstMac : int list, 
                   ipv4Packet : string} -> context -> context

end

(* 
    [initContext] Initializes and returns a fresh IPv4 handling context.

    [copyContext] Creates a copy of the given context.

    [handl] Handles incoming IPv4 packets by decoding and processing it 
    according to its destination and protocol information.
*)

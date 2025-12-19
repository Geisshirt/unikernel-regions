(* 
    The IPv4_SEND structure provides functionality for sending IPv4 fragments.
*)

signature IPV4_SEND = sig

    val send    : {ownMac : int list, 
                   ownIPaddr : int list,
                   identification : int, 
                   protocol : IPv4Codec.tl_protocol, 
                   dstIPaddr : int list, dstMac : int list,
                   payload : string} -> unit

end

(* 
    [send] Constructs an IPv4 packet and sends it to its specified destination.
*)

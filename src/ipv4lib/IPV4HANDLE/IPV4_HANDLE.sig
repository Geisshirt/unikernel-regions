signature IPV4_HANDLE = sig
    type context

    val initContext : unit -> context

    val copyContext : context`r -> context`r'

    val handl   : {ownIPaddr : int list,
                   ownMac : int list, 
                   dstMac : int list, 
                   ipv4Packet : string} -> context -> context

end
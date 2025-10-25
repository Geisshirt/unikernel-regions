signature IPV4_SEND = sig

    val send    : {ownMac : int list, 
                   ownIPaddr : int list,
                   identification : int, 
                   protocol : IPv4Codec.protocol, 
                   dstIPaddr : int list, dstMac : int list,
                   payload : string} -> unit

end

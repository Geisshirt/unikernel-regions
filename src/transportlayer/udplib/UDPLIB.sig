signature UDP = sig
    val handl : {
        service : Service.service,
        ownMac : int list,
        dstMac : int list,
        ownIPaddr : int list,
        dstIPaddr : int list,
        ipv4Header : IPv4Codec.header,
        udpPayload : string
    } -> unit
end
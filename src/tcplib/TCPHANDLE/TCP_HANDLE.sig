signature TCP_HANDLE = sig
    type port = int

    val handl : {
        bindings : (port * (string -> string)) list,
        ownMac : int list,
        dstMac : int list,
        ownIPaddr : int list,
        dstIPaddr : int list,
        ipv4Header : IPv4Codec.header,
        tcpPayload : string
    } -> unit
end
signature TCP = sig
    type context = TcpState.tcp_states

    type port = int

    val handl : {
        bindings : (port * (string -> string)) list,
        ownMac : int list,
        dstMac : int list,
        ownIPaddr : int list,
        dstIPaddr : int list,
        ipv4Header : IPv4Codec.header,
        tcpPayload : string
    } -> context -> context

    val initContext : unit -> context
end
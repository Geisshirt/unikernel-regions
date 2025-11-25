signature TCP = sig
    type context = TcpState.tcp_states

    val handl : {
        service: Service.service,
        ownMac : int list,
        dstMac : int list,
        ownIPaddr : int list,
        dstIPaddr : int list,
        ipv4Header : IPv4Codec.header,
        tcpPayload : string
    } -> context -> context

    val initContext : unit -> context
end
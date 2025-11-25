signature TCP_HANDLE = sig
    datatype info = INFO of {
        service    : Service.service,
        ownMac     : int list,
        dstMac     : int list,
        ownIPaddr  : int list,
        dstIPaddr  : int list,
        ipv4Header : IPv4Codec.header,
        payload : string
    }

    val initContext : unit -> context

    val handl : info -> TcpState.tcp_states -> TcpState.tcp_states
end
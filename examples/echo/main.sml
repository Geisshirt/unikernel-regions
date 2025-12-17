open Service

fun tcpService handlerRequest =
        (case handlerRequest of
            (8080, SETUP) => SETUP_STREAM
        |   (8080, REQUEST payload) => REPLY payload
        |   _ => IGNORE)

structure TL = 
    TransportLayerComb(
        structure tl = TransportLayerSingle(TcpHandler(val service = tcpService))
        structure tlh = UdpHandler(val service = fn (_, p) => p))

structure Net = Network(IPv4Handle( structure FragAssembler = FragAssemblerList;
                                    structure TransportLayer = TL))

local
in
    val _ = Net.listen ()
end
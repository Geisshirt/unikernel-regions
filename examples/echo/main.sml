open Service

fun myService handlerRequest =
        (case handlerRequest of
            (8081, TCPService, SETUP) => SETUP_STREAM
        |   (8081, TCPService, REQUEST payload) => REPLY (payload)
        |   _ => IGNORE)

structure TL = TransportLayerSingle(TcpHandler(val service = myService))
structure Net = Network(IPv4Handle( structure FragAssembler = FragAssemblerList;
                                    structure TransportLayer = TL))

local
in
    val _ = Net.listen ()
end
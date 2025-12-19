open Service

fun reverseService handlerRequest =
        (case handlerRequest of
            (8080, SETUP) => SETUP_FULL
        |   (8080, REQUEST payload) => REPLY (String.implode (List.rev (String.explode payload)))
        |   _ => IGNORE)

structure TL = 
    TransportLayerComb(
        structure tl = TransportLayerSingle(TcpHandler(val service = reverseService))
        structure tlh = UdpHandler(val service = fn (_, p) => p))

structure Net = Network(IPv4Handle( structure FragAssembler = FragAssemblerList;
                                    structure TransportLayer = TL))

local
in
    val _ = Net.listen ()
end

 
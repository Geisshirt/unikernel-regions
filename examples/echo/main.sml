structure TL = TransportLayerComb(structure tl = TransportLayerSingle(TcpHandler);
                                  structure tlh = UdpHandler)

structure NetworkDefault = Network(IPv4Handle(structure FragAssembler = FragAssemblerList; structure TransportLayer = TL))

(* structure NetworkDefault = Network(IPv4L) *)

open NetworkDefault
open Service

local
fun service handlerRequest =
        (case handlerRequest of
            (8080, UDPService, REQUEST payload) => REPLY payload
        |   (8081, TCPService, SETUP) => SETUP_STREAM
        |   (8081, TCPService, REQUEST payload) => REPLY payload
        |   _ => IGNORE)
in
val _ = listen service
end
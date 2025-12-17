
functor UdpHandler(val service : (int * string) -> string):> TRANSPORT_LAYER_HANDLER = struct
    open Logging
    open Protocols
    open Service

    type info = {
        ownMac     : int list,
        dstMac     : int list,
        ownIPaddr  : int list,
        dstIPaddr  : int list,
        ipv4Header : IPv4Codec.header,
        payload : string
    }

    type h_context = unit

    val protocol_int = 0x11

    val protocol_string = "UDP"

    type port = int

    fun initContext () = ()

    fun copyContext () = ()

    fun handl ({ownMac, dstMac, ownIPaddr, dstIPaddr, ipv4Header, payload}) () =
        let val (UdpCodec.Header udpHeader, udpPayload) = payload |> UdpCodec.decode
            val IPv4Codec.Header ipv4Header = ipv4Header
        in  log UDP (UdpCodec.Header udpHeader |> UdpCodec.toString) (SOME udpPayload);
            case service (#dest_port udpHeader, udpPayload) of
                payload => (
                    IPv4Send.send {
                        ownMac = ownMac,
                        ownIPaddr = ownIPaddr,
                        dstMac = dstMac,
                        dstIPaddr = dstIPaddr,
                        identification = (#identification ipv4Header), 
                        protocol = protocol_int, 
                        payload = (
                            UdpCodec.encode 
                                (UdpCodec.Header 
                                {   length = 0, 
                                    source_port = (#dest_port udpHeader), 
                                    dest_port = (#source_port udpHeader), 
                                    checksum = 0
                                })
                                payload
                            )
                    }
                )
            |   _ => ()
        end
end
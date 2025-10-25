open Logging
open Protocols

structure Udp :> UDP = struct
    type port = int

    fun handl {bindings, ownMac, dstMac, ownIPaddr, dstIPaddr, ipv4Header, udpPayload} =
        let val (UdpCodec.Header udpHeader, udpPayload) = udpPayload |> UdpCodec.decode
            val binding = List.find (fn (port, cb) => (#dest_port udpHeader) = port) bindings
            val IPv4Codec.Header ipv4Header = ipv4Header
            val payload = (
                case binding of
                  SOME (_, cb) => cb udpPayload
                | NONE => "Port is not mapped to a function.\n"
            )
            val udpHeader = (UdpCodec.Header 
                            {   length = 0, 
                                source_port = (#dest_port udpHeader), 
                                dest_port = (#source_port udpHeader), 
                                checksum = 0
                            }
                        )
        in  log UDP (udpHeader |> UdpCodec.toString) (SOME udpPayload);
            IPv4Send.send {
                ownMac = ownMac,
                ownIPaddr = ownIPaddr,
                dstMac = dstMac,
                dstIPaddr = dstIPaddr,
                identification = (#identification ipv4Header), 
                protocol = UDP, 
                payload = (
                    UdpCodec.encode 
                        udpHeader
                        payload
                    )
            }
        end
end
open Logging

structure Udp :> UDP = struct
    type port = int

    datatype header = Header of {
        source_port: int,
        dest_port: int,
        length : int,
        checksum: int
    } 

    fun handl {bindings, ownMac, dstMac, ownIPaddr, dstIPaddr, ipv4Header, udpPayload} =
        let val (CodecUDP.Header udpHeader, udpPayload) = udpPayload |> CodecUDP.decode
            val binding = List.find (fn (port, cb) => (#dest_port udpHeader) = port) bindings
            val IPv4Codec.Header ipv4Header = ipv4Header
            val payload = (
                case binding of
                  SOME (_, cb) => cb udpPayload
                | NONE => "Port is not mapped to a function.\n"
            )
            val udpHeader = (CodecUDP.Header 
                            {   length = 0, 
                                source_port = (#dest_port udpHeader), 
                                dest_port = (#source_port udpHeader), 
                                checksum = 0
                            }
                        )
        in  log UDP (udpHeader |> CodecUDP.toString) (SOME udpPayload);
            IPv4Send.send {
                ownMac = ownMac,
                ownIPaddr = ownIPaddr,
                dstMac = dstMac,
                dstIPaddr = dstIPaddr,
                identification = (#identification ipv4Header), 
                protocol = IPv4Codec.UDP, 
                payload = (
                    CodecUDP.encode 
                        udpHeader
                        payload
                    )
            }
        end
end
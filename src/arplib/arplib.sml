open Logging

structure Arp :> ARP = struct 

    fun handl {ownMac, ownIPaddr, dstMac, arpPacket} =
        let val arp = SOME (arpPacket |> ARPCodec.decode) handle _ => NONE
        in
            case arp of
                SOME (ARPCodec.Header arpHeader) => 
                    if #tpa arpHeader = ownIPaddr then (
                        log ARP (ARPCodec.toString (ARPCodec.Header arpHeader)) NONE;
                        Eth.send {
                            ownMac = ownMac, 
                            dstMac = dstMac, 
                            ethType = EthCodec.ARP, 
                            ethPayload = 
                                ARPCodec.encode (ARPCodec.Header {
                                    htype = 1, 
                                    ptype = 0x0800,
                                    hlen = 6,
                                    plen = 4,
                                    oper = ARPCodec.Reply,
                                    sha = ownMac, 
                                    spa = ownIPaddr,
                                    tha = (#sha arpHeader),
                                    tpa = List.concat [(#spa arpHeader), [0, 0]]
                                })
                        }
                    ) else ()
            |   NONE => logMsg Logging.ARP "Arp packet could not be decoded\n"
        end
end 


open Logging

functor IPv4Handle(FragAssembler : FRAG_ASSEMBLER) :> IPV4_HANDLE = struct
    type fragContainer = FragAssembler.fragContainer

    fun emptyFragContainer () = FragAssembler.empty()

    type port = int

    type bindingList = (port * (string -> string)) list

    datatype pbindings = PBindings of {
      UDP : bindingList, 
      TCP : bindingList
    }

    val mtu = 1500

    fun mkPktID (IPv4Codec.Header ipv4Hdr) = 
        rawBytesString (#source_addr ipv4Hdr) ^
        Int.toString (#identification ipv4Hdr) ^
        IPv4Codec.protToString (#protocol ipv4Hdr)

    fun handl {fragContainer, 
               protBindings,
               ownIPaddr,
               ownMac,
               dstMac,
               ipv4Packet } =
        let val PBindings protBindings = protBindings
            val (IPv4Codec.Header ipv4Header, ipv4Pay) = IPv4Codec.decode ipv4Packet
            val (payloadOpt, new_m0) = 
                    if (#fragment_offset ipv4Header) = 0 andalso (#flags ipv4Header) = 2 
                    then (SOME ipv4Pay, fragContainer)
                    else let val pktID = (mkPktID (IPv4Codec.Header ipv4Header))
                             val new_m1 = FragAssembler.add pktID
                                                (FragAssembler.Fragment {
                                                    offset = #fragment_offset ipv4Header,
                                                    length = ((#total_length ipv4Header) - 20) div 8,
                                                    fragPayload = ipv4Pay,
                                                    isLast = (#flags ipv4Header) = 0
                                                })
                                                fragContainer
                            in  case FragAssembler.assemble pktID new_m1 of 
                                    SOME (payload, new_m2) => (SOME payload, new_m2)
                                |   NONE => (NONE, new_m1)
                            end
        in  if #dest_addr ipv4Header = ownIPaddr then (
                log IPv4 (IPv4Codec.toString (IPv4Codec.Header ipv4Header)) NONE;
                case payloadOpt of 
                    SOME payload => (
                        case (#protocol ipv4Header) of 
                          UDP => 
                                Udp.handl {
                                    bindings = #UDP protBindings,
                                    ownMac = ownMac, 
                                    dstMac = dstMac,
                                    ownIPaddr = ownIPaddr,
                                    dstIPaddr = #source_addr ipv4Header,
                                    ipv4Header = IPv4Codec.Header ipv4Header,
                                    udpPayload = payload
                                }
                          | TCP => 
                                Tcp.handl {
                                    bindings = #TCP protBindings,
                                    ownMac = ownMac, 
                                    dstMac = dstMac,
                                    ownIPaddr = ownIPaddr,
                                    dstIPaddr = #source_addr ipv4Header,
                                    ipv4Header = IPv4Codec.Header ipv4Header,
                                    tcpPayload = payload
                                }
                        | _ =>  logMsg IPv4 "IPv4 Handler: Protocol is not supported.\n"
                    )
                |   NONE => ()
            ) else ();
            new_m0
        end
end

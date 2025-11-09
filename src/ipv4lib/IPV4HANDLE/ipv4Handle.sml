functor IPv4Handle(FragAssembler : FRAG_ASSEMBLER) :> IPV4_HANDLE = struct
    open Logging

    datatype context = Context of {
        fragContainer : FragAssembler.fragContainer,
        tcpContext : Tcp.context
    }

    type context = context

    type port = int

    type bindingList = (port * (string -> string)) list

    datatype pbindings = PBindings of {
      UDP : bindingList, 
      TCP : bindingList
    }

    val mtu = 1500

    fun initContext () = Context {
        fragContainer = FragAssembler.empty(),
        tcpContext = Tcp.initContext()
    }

    fun mkPktID (IPv4Codec.Header ipv4Hdr) = 
        rawBytesString (#source_addr ipv4Hdr) ^
        Int.toString (#identification ipv4Hdr) ^
        IPv4Codec.protToString (#protocol ipv4Hdr)

    fun handl {protBindings,
               ownIPaddr,
               ownMac,
               dstMac,
               ipv4Packet } (Context context) =
        let val PBindings protBindings = protBindings
            val (IPv4Codec.Header ipv4Header, ipv4Pay) = IPv4Codec.decode ipv4Packet
            val (payloadOpt, new_m0) = 
                    if (#fragment_offset ipv4Header) = 0 andalso (#flags ipv4Header) = 2 
                    then (SOME ipv4Pay, #fragContainer context)
                    else let val pktID = (mkPktID (IPv4Codec.Header ipv4Header))
                             val new_m1 = FragAssembler.add pktID
                                                (FragAssembler.Fragment {
                                                    offset = #fragment_offset ipv4Header,
                                                    length = ((#total_length ipv4Header) - 20) div 8,
                                                    fragPayload = ipv4Pay,
                                                    isLast = (#flags ipv4Header) = 0
                                                })
                                                (#fragContainer context)
                            in  case FragAssembler.assemble pktID new_m1 of 
                                    SOME (payload, new_m2) => (SOME payload, new_m2)
                                |   NONE => (NONE, new_m1)
                            end
            val newContext = { fragContainer = new_m0, tcpContext = (#tcpContext context) }
        in  if #dest_addr ipv4Header = ownIPaddr then (
                log IPv4 (IPv4Codec.toString (IPv4Codec.Header ipv4Header)) NONE;
                case payloadOpt of 
                    SOME payload => (
                        case (#protocol ipv4Header) of 
                          UDP => 
                                (Udp.handl {
                                    bindings = #UDP protBindings,
                                    ownMac = ownMac, 
                                    dstMac = dstMac,
                                    ownIPaddr = ownIPaddr,
                                    dstIPaddr = #source_addr ipv4Header,
                                    ipv4Header = IPv4Codec.Header ipv4Header,
                                    udpPayload = payload
                                };
                                Context newContext)
                          | TCP => 
                                let val newTcpContext = Tcp.handl {
                                            bindings = #TCP protBindings,
                                            ownMac = ownMac, 
                                            dstMac = dstMac,
                                            ownIPaddr = ownIPaddr,
                                            dstIPaddr = #source_addr ipv4Header,
                                            ipv4Header = IPv4Codec.Header ipv4Header,
                                            tcpPayload = payload
                                        } (#tcpContext context)
                                in  Context {
                                        fragContainer = new_m0,
                                        tcpContext = newTcpContext
                                    }
                                end
                        | _ => (
                            logMsg IPv4 "IPv4 Handler: Protocol is not supported.\n";
                            Context newContext
                        )
                    )
                |   NONE => Context newContext
            ) 
            else Context newContext
        end
end

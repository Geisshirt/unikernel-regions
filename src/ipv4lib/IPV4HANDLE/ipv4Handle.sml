functor IPv4Handle(structure FragAssembler : FRAG_ASSEMBLER
                   structure TransportLayer : TRANSPORT_LAYER) :> IPV4_HANDLE = struct
    open Logging

    datatype context = Context of {
        fragContainer : FragAssembler.fragContainer,
        tlContext : TransportLayer.context
    }

    type context = context

    type port = int

    val mtu = 1500

    fun initContext () = Context {
        fragContainer = FragAssembler.empty(),
        tlContext = TransportLayer.initContext()
    }

    fun copyContext (Context c) = Context {
        fragContainer = FragAssembler.copy (#fragContainer c),
        tlContext = TransportLayer.copyContext (#tlContext c)
    }

    fun mkPktID (IPv4Codec.Header ipv4Hdr) = 
        rawBytesString (#source_addr ipv4Hdr) ^
        Int.toString (#identification ipv4Hdr) ^
        TransportLayer.protToString (#protocol ipv4Hdr)

    fun handl {ownIPaddr,
               ownMac,
               dstMac,
               ipv4Packet } (Context context) =
        let val (IPv4Codec.Header ipv4Header, ipv4Pay) = IPv4Codec.decode ipv4Packet
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
            val newContext = { fragContainer = new_m0, tlContext = (#tlContext context) }
        in  if #dest_addr ipv4Header = ownIPaddr then (
                log IPv4 (IPv4Codec.toString (IPv4Codec.Header ipv4Header)) NONE;
                case payloadOpt of 
                    SOME payload => 
                        let val new_tlcontext = TransportLayer.handl (#protocol ipv4Header) (TransportLayer.INFO {
                                    ownMac = ownMac, 
                                    dstMac = dstMac,
                                    ownIPaddr = ownIPaddr,
                                    dstIPaddr = #source_addr ipv4Header,
                                    ipv4Header = IPv4Codec.Header ipv4Header,
                                    payload = payload
                                }) (#tlContext context)
                        in Context {
                                        fragContainer = new_m0,
                                        tlContext = new_tlcontext
                                    }
                        end
                |   NONE => Context newContext
            ) 
            else Context newContext
        end
end

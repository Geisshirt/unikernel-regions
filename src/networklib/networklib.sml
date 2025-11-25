functor Network(IPv4 : IPV4_HANDLE) :> NETWORK = struct
    open Logging

    type port = int
    type callback = string -> string

    val ownMac = [0x7c, 0x75, 0xb2, 0x39, 0xd4, 0x84]

    val ownIPaddr = [10, 0, 0, 2]
    (* val ownIPaddr= [172, 44, 0, 2] *)

    val log = ref false

    fun logPrint str = if !log then print str else ()

    fun logOn () = log := true 

    fun logOff () = log := false

    fun recListen context service = 
        let 
            val rawTap = Netif.receive () 
            (* TODO: Why are we doing this pointless extract? *)
            val ethFrame = String.extract (rawTap, 0, NONE)
            val (ethHeader, ethPayload) = ethFrame |> EthCodec.decode 
            val EthCodec.Header {et, dstMac, srcMac} = ethHeader
            val new_context = 
                if dstMac = ownMac orelse dstMac = [255, 255, 255, 255, 255, 255] then (
                    EthCodec.toString ethHeader |> logPrint;
                    (case et of 
                      ARP => (
                        Arp.handl {
                            ownMac = ownMac, 
                            ownIPaddr = ownIPaddr,
                            dstMac = srcMac,
                            arpPacket = ethPayload
                        };
                        context
                    )
                    (* List.filter (fn (prot, _) => prot = TCP) bindings |> map (fn (_, l) => l) *)
                    | IPv4 => 
                        IPv4.handl {
                            service = service,
                            ownIPaddr = ownIPaddr,
                            ownMac = ownMac,
                            dstMac = srcMac,
                            ipv4Packet = ethPayload
                        } context
                    | _ => (print "\nIn listen: Protocol not supported.\n"; context)
                    )
                ) else context
        in 
            recListen new_context service
        end 
       (* handle _ => (print "Encountered an error in handling!\n"; recListen context bindings)  *)

    fun listen service = 
        recListen (IPv4.initContext ()) service

end

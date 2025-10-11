open Logging

functor Network(IPv4 : IPV4_HANDLE) :> NETWORK = struct
    type port = int
    type callback = string -> string

    val ownMac = [0x7c, 0x75, 0xb2, 0x39, 0xd4, 0x84]

    val ownIPaddr = [10, 0, 0, 2]
    (* val ownIPaddr= [172, 44, 0, 2] *)

    val log = ref false

    fun logPrint str = if !log then print str else ()

    fun logOn () = log := true 

    fun logOff () = log := false

    fun recListen m bindings = 
        let 
            val rawTap = Netif.receive () 
            val ethFrame = String.extract (rawTap, 0, NONE)
            val (ethHeader, ethPayload) = ethFrame |> EthCodec.decode 
            val EthCodec.Header {et, dstMac, srcMac} = ethHeader
            val new_m = 
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
                        m
                    )
                    (* List.filter (fn (prot, _) => prot = TCP) bindings |> map (fn (_, l) => l) *)
                    | IPv4 => 
                        IPv4.handl {
                            fragContainer = m,
                            protBindings = IPv4.PBindings {
                                UDP = List.filter (fn (prot, _) => prot = UDP) bindings |> map (fn (_, l) => l) |> foldl (op @) [],
                                TCP = List.filter (fn (prot, _) => prot = TCP) bindings |> map (fn (_, l) => l) |> foldl (op @) []
                            },
                            ownIPaddr = ownIPaddr,
                            ownMac = ownMac,
                            dstMac = srcMac,
                            ipv4Packet = ethPayload
                        }
                    | _ => (print "\nIn listen: Protocol not supported.\n"; m)
                    )
                ) else m
        in 
            recListen new_m bindings
        end handle _ => (print "Encountered an error in handling!\n"; recListen m bindings)


    fun listen bindings = 
        recListen (IPv4.emptyFragContainer()) bindings

end

structure IPv4L = IPv4Handle(FragAssemblerList)

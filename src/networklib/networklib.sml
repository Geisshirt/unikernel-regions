functor Network(IPv4 : IPV4_HANDLE) :> NETWORK = struct
    open Logging

    type port = int
    type callback = string -> string

    fun ownMac () = [0x7c, 0x75, 0xb2, 0x39, 0xd4, 0x84]

    fun ownIPaddr () = [10, 0, 0, 2]
    (* val ownIPaddr= [172, 44, 0, 2] *)

    (* val log = ref false

    fun logPrint str = if !log then print str else ()

    fun logOn () = log := true

    fun logOff () = log := false *)

    fun recListen (context : IPv4.context) : IPv4.context =
         let val new_context : IPv4.context =
                let val ethFrame = Netif.receive ()
                    val (ethHeader, ethPayload) = ethFrame |> EthCodec.decode
                    val EthCodec.Header {et, dstMac, srcMac} = ethHeader
                    fun compare [] [] = true
                      | compare [] _ = false 
                      | compare _ [] = false 
                      | compare (x::xs) (y::ys) = if x <> y then false else compare xs ys
                in
                    if compare dstMac (ownMac ()) orelse compare dstMac [255, 255, 255, 255, 255, 255] then (
                        (* EthCodec.toString ethHeader |> logPrint; *)
                        case et of
                        ARP => (
                            Arp.handl {
                                ownMac = ownMac (),
                                ownIPaddr = ownIPaddr (),
                                dstMac = srcMac,
                                arpPacket = ethPayload
                            };
                            context
                        )
                        (* List.filter (fn (prot, _) => prot = TCP) bindings |> map (fn (_, l) => l) *)
                        | IPv4 =>
                            IPv4.handl {
                                ownIPaddr = ownIPaddr (),
                                ownMac = ownMac (),
                                dstMac = srcMac,
                                ipv4Packet = ethPayload ^ ""
                            } context
                        | _ => (print "\nIn listen: Protocol not supported.\n"; context)
                    ) else context
                end
        in
            new_context
        end
       (* handle _ => (print "Encountered an error in handling!\n"; recListen context bindings)  *)
    local
    fun listen' (context : IPv4.context) =
        listen' ( 
            if !(ref false) then context else (
                let val temp = IPv4.copyContext (recListen context)
                    val _ = forceResetting context
                in
                    (IPv4.copyContext temp)
                end))
    in
    fun listen () =
        let val context = IPv4.initContext ()
        in
            Netif.init();
            listen' (context);
            ()
        end
    end

end

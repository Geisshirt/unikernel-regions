functor Network(IPv4 : IPV4_HANDLE) :> NETWORK = struct
    open Logging

    type port = int

    type callback = string -> string
    
    val count = ref 0

    fun ownMac () = [0x7c, 0x75, 0xb2, 0x39, 0xd4, 0x84]

    fun parseIP s =
        let 
            val d = String.tokens (fn d => d = #".") s
            fun toInt i = 
                case Int.fromString i of
                    SOME i => 
                        if 0 <= i andalso i <= 255 then i
                        else raise Fail "Digit of IP not in range 0-255."
                |   NONE => raise Fail "Non-valid digit in IP."
        in
            if length d <> 4 
            then raise Fail "Given non-valid IP length."
            else map toInt d
        end

    val ipaddr = (
        case List.find (String.isPrefix "ip=") (CommandLine.arguments ()) of
            SOME s => String.extract(s, 3, NONE) |> parseIP
        |   NONE => raise Fail "Missing IP argument."
    )

    fun ownIPaddr () = copyList (fn i => i) ipaddr
        
    (* fun ownIPaddr () = [10, 0, 0, 2] *)
    (* fun ownIPaddr () = [172, 44, 0, 2]  *)

    fun intListToString l = String.concatWith "." (map Int.toString l)  

    fun recListen (context : IPv4.context) : IPv4.context =
         let val new_context : IPv4.context =
                let val ethFrame = Netif.receive ()
                    val (ethHeader, ethPayload) = EthCodec.decode ethFrame
                    val EthCodec.Header {ethType, dstMac, srcMac} = ethHeader
                    fun compare [] [] = true
                      | compare [] _ = false
                      | compare _ [] = false
                      | compare (x::xs) (y::ys) = x = y andalso compare xs ys
                in
                    if compare dstMac (ownMac ()) orelse 
                       compare dstMac [255, 255, 255, 255, 255, 255] then (
                        case ethType of
                          ARP => (
                            Arp.handl {
                                ownMac = ownMac (),
                                ownIPaddr = ownIPaddr (),
                                dstMac = srcMac,
                                arpPacket = ethPayload
                            };
                            context
                        )
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
            count := !count + 1;
            if !(ref false) then context 
            else if !count mod 1000 = 0 then (
                let val temp = IPv4.copyContext (recListen context)
                    val _ = resetRegions context
                in
                    count := 0;
                    (IPv4.copyContext temp)
                end)
                
                
                (* No use of double copy *)
                (* let
                    val temp = IPv4.copyContext (recListen context)
                    val _ = resetRegions context
                in
                    count := 0;
                    temp
                end) *)

            else (recListen context)) 
    in
    fun listen () =
        let val context = IPv4.initContext ()
        in                                                                                                                                                                
            print "       ######                                               \n";
            print "   .#############.     Powered by:                 **       \n";
            print " .##   ## # ##  ##.    ####  ####   ##     ##  ##  ##   ##  \n";
            print "#####           ####   ####  ####   ##     ## ##   ## ######\n";
            print " ###### #  #  #####    # ##.#  ##   ##     ####    ##   ##  \n";
            print "  ###        #####     #  ###  ##   ##     ## ##   ##   ##  \n";
            print "   #   #    #####      #   ##   #   #####  ##  ##  ##   ##  \n";
            print "     ###    ####                                            \n";
            print "    ###########                                             \n";                                                     
            print ("Started listening on " ^ intListToString (ownIPaddr ()) ^ 
                   " with MAC address " ^ intListToString (ownMac ()) ^"!\n");
            Netif.init();
            listen' context;
            ()
        end
    end

end

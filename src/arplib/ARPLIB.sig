(* 
    The ARP structure provides handling of arp packets
*)

signature ARP = sig

    val handl : {ownMac : int list,
                 ownIPaddr : int list,
                 dstMac : int list, 
                 arpPacket : string
                 } -> unit 

end

(*
[handleArp] This functions handles ARP packets, by decoding the arp-packet data
            and then sending 
*)
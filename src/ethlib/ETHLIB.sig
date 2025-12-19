(* 
    The ETH structure provides sending of ethernet frames.
*)

signature ETH = sig

    val send :  {ownMac : int list,
                 dstMac : int list, 
                 ethType : Protocols.protocol,
                 ethPayload : string
                 } -> unit 

end

(*
    [send] Sends the ethernet frame over the network.
*)
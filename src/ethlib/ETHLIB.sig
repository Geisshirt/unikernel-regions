(* 
    The ETH structure provides sending of ethernet frames
*)

signature ETH = sig

    val send :  {ownMac : int list,
                 dstMac : int list, 
                 ethType : EthCodec.ethType,
                 ethPayload : string
                 } -> unit 

end

(*
[send]  This function 
*)
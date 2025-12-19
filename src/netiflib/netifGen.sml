(* Generator for netif *)
structure Netif : NETIF = struct
  (* Empty file *)
  fun init () = TextIO.closeOut (TextIO.openOut "eth.bin" );

  fun receive() : string =
    let val outputFile = TextIO.openAppend "eth.bin"
        val received = prim ("Receive", ()) 
    in 
      TextIO.output (outputFile, Int.toString (String.size received) ^ "\n\n");
      TextIO.output (outputFile, received ^ "\n\n");
      TextIO.flushOut outputFile;
      received
    end 

  fun send(byte_list : int list) : unit =
    prim ("Send", byte_list)
end 
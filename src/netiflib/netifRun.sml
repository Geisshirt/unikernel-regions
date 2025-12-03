(* Generator for netif *)
structure Netif :> NETIF = struct
  (* Empty file *)

  val inputFile = TextIO.openIn "eth.bin"

  fun init () = ()

  fun count 0 = ()
    | count n = count (n-1)

  fun receive() : string =
    let fun getLen s = 
          case TextIO.input1 inputFile of 
            SOME (#"\n") => (TextIO.input1 inputFile; valOf (Int.fromString s))
          | SOME c => getLen (s ^ (Char.toString c))
          | NONE => 0
    in 
      if TextIO.endOfStream inputFile then
        ( 
          (* count 2000000000; *)
          OS.Process.exit OS.Process.success
        )
      else 
        let val len = getLen ""
            val input = TextIO.inputN (inputFile, len)
        in 
          TextIO.inputN (inputFile, 2);
          input 
        end 
    end 

  fun send(byte_list : int list) : unit = ()
end 
(* Generator for netif *)
structure Netif :> NETIF = struct
  val fd = Posix.FileSys.openf("eth.bin", Posix.FileSys.O_RDONLY, Posix.FileSys.O.flags nil)

  fun init () = ()

  fun receive() : string =
    let fun readChar () =
            let val v = Posix.IO.readVec(fd, 1) in
              if Word8Vector.length v = 1
              then SOME (Byte.byteToChar(Word8Vector.sub(v, 0)))
              else NONE
            end
        fun readString n =
          let val v = Posix.IO.readVec(fd, n) in
            if Word8Vector.length v = n
            then Byte.bytesToString v
            else raise Fail "Could not read string"
          end
        fun getLen s =
          case readChar () of
            SOME (#"\n") => (readChar (); valOf (Int.fromString s))
          | SOME c => getLen (s ^ (Char.toString c))
          | NONE => (
            (* Close file? *)
            OS.Process.exit OS.Process.success
          )
    in
      let val len = getLen ""
          val input = readString len
      in
        readString 2;
        input
      end
    end

  fun send(byte_list : int list) : unit = ()
end
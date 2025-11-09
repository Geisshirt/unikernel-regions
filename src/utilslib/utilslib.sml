(* structure Utils : UTILSLIB = 
      struct  *)

infix 3 |> fun x |> f = f x

infix 8 ** fun x ** y = Math.pow (Real.fromInt x, Real.fromInt y) |> round 

fun findi f l =
      let fun findi_ [] _ = NONE
            | findi_ (h::t) i = if f h then SOME (i, h) else findi_ t (i+1)
      in  findi_ l 0
      end

fun toHextets [] = []
    | toHextets [x] = [x]
    | toHextets (x::y::t) = x * (2 ** 8) + y :: toHextets t

fun toByteList (s : string) : int list = s |> explode |> map Char.ord 

fun rawBytesString (b: int list) = b |> foldl (fn (x, acc) => if acc = "" then (Int.toString x) else acc ^ " " ^ (Int.toString x)) ""

fun byteListToString b = (b |> map Char.chr |> implode)

(* Check with char? *)
fun intToRawbyteString i0 nb = 
    let fun h_intToRawbyteString i 1 acc = Char.chr i :: acc |> implode
          | h_intToRawbyteString i nb acc = 
            if nb <= 0 then ""
            else Char.chr (i mod 256) :: acc |> h_intToRawbyteString (i div 256) (nb-1)
    in 
        h_intToRawbyteString i0 nb []
    end

fun getLBits octet nb = octet div (2**(8-nb))

fun getRBits octet nb = octet mod (2**nb)

fun setLBits num nb = num * (2**(8-nb))

fun makeChecksum l =
    let
        val sum = List.foldl (op +) 0 l
        val carry = (sum - getRBits sum 16) div (2 ** 16)
        val sumWithoutCarry = sum - (sum - getRBits sum 16)
    in
        sumWithoutCarry + carry
        |> Word.fromInt
        |> Word.notb
        |> (fn w => Word.andb (Word.fromInt 0xFFFF, w))
        |> Word.toInt
    end

fun printCharsOfRawbytes s =
    s 
    |> map (fn x => (Char.chr x |> Char.toString) ^ " ") 
    |> app print

fun convertRawBytes s : int = 
    s
    |> toByteList 
    |> foldl (fn (c, acc) => acc*256+c) 0 

fun printRawBytes s =
    s
    |> toByteList
    |> map (fn x => (Int.toString x) ^ " ")
    |> app print 
      (* end  *)

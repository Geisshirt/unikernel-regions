open Service

val facTbl = ref (Vector.fromList [])

fun fac n : IntInf.int = (
    if IntInf.fromInt (Vector.length (!facTbl)) >= n then Vector.sub (!facTbl, IntInf.toInt n-1)
    else
        let val x = if n <= 1 then 1 else fac(n-1) * n in
            facTbl := Vector.concat [!facTbl, (Vector.fromList [x])];
            x
        end
)

val fibTbl = ref (Vector.fromList [])

fun fib n : IntInf.int = (
    if IntInf.fromInt (Vector.length (!fibTbl)) > n then Vector.sub (!fibTbl, IntInf.toInt n)
    else
        let val x = if n < 2 then n else (fib(n-2) + fib(n-1)) in
            fibTbl := Vector.concat [!fibTbl, (Vector.fromList [x])];
            x
        end
)

fun fastFib n : IntInf.int =
    if n < 0 then raise Fail "Negative arguments not implemented"
    else #1 (fastFibH n)

and fastFibH 0 : IntInf.int * IntInf.int = (IntInf.fromInt 0, IntInf.fromInt 1)
  | fastFibH n : IntInf.int * IntInf.int =
    let
        val (a, b) = fastFibH (n div 2)
        val c = a * (b * 2 - a)
        val d = a * a + b * b
    in
        if n mod 2 = 0 then (c, d)
        else (d, c + d)
    end

fun myService handlerRequest =
        (case handlerRequest of
            (8080, SETUP) => SETUP_FULL
        |   (8080, REQUEST payload) => REPLY (case IntInf.fromString payload of
                                                            SOME n => fac n |> IntInf.toString
                                                         |  NONE   => "Invalid input")
        |   (8081, SETUP) => SETUP_FULL
        |   (8081, REQUEST payload) => REPLY (case IntInf.fromString payload of
                                                            SOME n => fib n |> IntInf.toString
                                                         |  NONE   => "Invalid input")
        |   (8082, SETUP) => SETUP_FULL
        |   (8082, REQUEST payload) => REPLY (case Int.fromString payload of
                                                            SOME n => fastFib n |> IntInf.toString
                                                         |  NONE   => "Invalid input")
        |   _ => IGNORE)

structure TL = TransportLayerSingle(TcpHandler(val service = myService))
structure Net = Network(IPv4Handle( structure FragAssembler = FragAssemblerList;
                                    structure TransportLayer = TL))

local
in
    val _ = Net.listen ()
end

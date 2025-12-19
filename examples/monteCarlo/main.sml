open Service

structure Sobol = Sobol(val D = 2
                        structure SobolDir = SobolDir50)

fun monteCarlo n =
    let
        fun loop 0 UC = UC
          | loop i UC =
                let
                    val v = Sobol.independent i
                    val x = Sobol.frac(Array.sub(v,0))
                    val y = Sobol.frac(Array.sub(v,1))
                    val new_UC = if (x * x + y * y <= 1.0) then UC + 1 else UC
                in
                    loop (i - 1) new_UC
                end
        val UC = loop n 0
    in
        4.0 * (Real.fromInt UC) / (Real.fromInt n)
    end

fun MCService handlerRequest =
        (case handlerRequest of
            (8080, SETUP) => SETUP_FULL
        |   (8080, REQUEST payload) => REPLY (case Int.fromString payload of
                                                SOME n => monteCarlo n |> Real.toString
                                              | NONE => "Invalid input")
        |   _ => IGNORE)

structure TL = 
    TransportLayerComb(
        structure tl = TransportLayerSingle(TcpHandler(val service = MCService))
        structure tlh = UdpHandler(val service = fn (_, p) => p))

structure Net = Network(IPv4Handle( structure FragAssembler = FragAssemblerList;
                                    structure TransportLayer = TL))

local
in
    val _ = Net.listen ()
end
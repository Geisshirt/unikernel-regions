signature LOGGING = sig
    type protocol = Protocols.protocol
    val enable : { protocols : protocol list, level : int } -> unit
    val isEnabled : protocol -> bool
    val log : protocol -> string -> string option -> unit
    val logMsg : protocol -> string -> unit
end

structure Logging :> LOGGING = struct
    open Protocols

    fun print (s:string) : unit = prim("printStringML", s)

    val loggingEnabled = ref false
    val currentLevel   = ref 1
    val activeProtocols : protocol list ref = ref []

    fun enable { protocols, level } =
        (loggingEnabled := true;
         currentLevel := level;
         activeProtocols := protocols)

    fun isEnabled prot =
        !loggingEnabled andalso List.exists (fn p => p = prot) (!activeProtocols)

    fun log (prot: protocol) (header: string) (payload: string option) =
        if isEnabled prot then (
            if !currentLevel >= 2 then print (header ^ "\n")
            else ();
            if !currentLevel >= 1 then
                case payload of
                      SOME p => print ("Payload: " ^ p ^ "\n")
                    | NONE => ()
            else ()
        ) else ()

    fun logMsg (prot: protocol) (msg: string) =
        if isEnabled prot then print (msg ^ "\n") else ()
end

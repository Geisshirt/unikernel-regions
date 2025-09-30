structure Logging : LOGGING = struct
    datatype protocol = ARP | IPv4 | UDP | TCP | Other

    val loggingEnabled = ref false
    val currentLevel   = ref 1
    val activeProtocols : protocol list ref = ref []

    fun enable { protocols, level } =
        (loggingEnabled := true;
         currentLevel := level;
         activeProtocols := protocols)

    fun isEnabled prot =
        !loggingEnabled andalso List.exists (fn p => p = prot) (!activeProtocols)

    fun logMsg prot msg =
        if isEnabled prot then print msg else ()

    fun logARP (ARP.Header arp) =
        if isEnabled ARP then (
            if !currentLevel >= 2 then
                ARP.toString (ARP.Header arp) |> print
            else ()
        ) else ()

    fun logIPv4 (IPv4.Header hdr, payload) =
        if isEnabled IPv4 then (
            if !currentLevel >= 2 then IPv4.toString (IPv4.Header hdr) |> print else ();
            if !currentLevel >= 1 then (
                print "Payload: ";
                print payload;
                print "\n"
            ) else ()
        ) else ()

    fun logUDP (UDP.Header hdr, payload) =
        if isEnabled UDP then (
            if !currentLevel >= 2 then UDP.toString (UDP.Header hdr) |> print else ();
            if !currentLevel >= 1 then (
                print "Payload: ";
                print payload;
                print "\n"
            ) else ()
        ) else ()

    fun logTCP (TCP.Header hdr, payload) =
        if isEnabled TCP then (
            if !currentLevel >= 2 then TCP.toString (TCP.Header hdr) |> print else ();
            if !currentLevel >= 1 then (
                print "Payload: ";
                print payload;
                print "\n"
            ) else ()
        ) else ()
end

structure Logger = Logging

open Network


val _ = (
    (* Logging.enable {protocols=[IPv4], level = 2}; *)
    logOn();
    bindUDP 8080 (fn data => data);
    listen ()
)

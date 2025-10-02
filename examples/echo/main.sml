open Network
open Logging

val _ = (
    enable {protocols=[UDP], level = 2};
    bindUDP 8080 (fn data => data);
    listen ()
)

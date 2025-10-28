open Net
open Protocols

val _ = (
    Logging.enable {protocols=[UDP], level = 2};
    listen [
        (UDP, [(8080, fn data => data)])
       ]
)

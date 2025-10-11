structure NetworkDefault = Network(IPv4L)

open NetworkDefault
open Protocols (* Include in default? *)

val _ = (
    Logging.enable {protocols=[UDP], level = 2};
    listen [
            (UDP, [(8080, fn data => data)])
           ]
)

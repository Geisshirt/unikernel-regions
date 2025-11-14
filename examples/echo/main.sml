structure NetworkDefault = Network(IPv4L)

open NetworkDefault
open Protocols (* Include in default? *)

val _ = (
    listen [
            (UDP, [(8080, fn data => data)]),
            (TCP, [(8081, fn data => data)])
           ]
)

structure NetworkDefault = Network(IPv4L)

open NetworkDefault

val _ = (
    (* Logging.enable {protocols=[IPv4], level = 2}; *)
    listen [
            (UDP, [(8080, fn data => data)])
           ]
)

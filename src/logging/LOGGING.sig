
signature LOGGING = sig
    datatype protocol = ARP | IPv4 | UDP | TCP | Other

    val enable   : { protocols : protocol list, level : int } -> unit

    val log      : protocol -> string -> string option -> unit
    val logMsg   : protocol -> string -> unit
    (* val logARP   : ARP.header -> unit
    val logIPv4  : IPv4.header * string -> unit
    val logUDP   : UDP.header * string -> unit
    val logTCP   : TCP.header * string -> unit *)
end

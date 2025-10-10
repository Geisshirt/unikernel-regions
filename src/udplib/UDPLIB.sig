signature UDP = sig
    type port = int

    datatype header = Header of {
        source_port: int,
        dest_port: int,
        length : int,
        checksum: int
    } 

    val handl : {
        bindings : (port * (string -> string)) list,
        ownMac : int list,
        dstMac : int list,
        ownIPaddr : int list,
        dstIPaddr : int list,
        ipv4Header : IPv4Codec.header,
        udpPayload : string
    } -> unit
end
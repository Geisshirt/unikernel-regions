(*
    The TCPLib structure provides to de- and encode TCP headers.
*)

signature TCP_CODEC = sig
    datatype flag = FIN | SYN | RST | PSH | ACK | URG | ECE | CWR
    
    datatype header = Header of {
        source_port: int,
        dest_port: int,
        sequence_number: int,
        ack_number: int,
        DOffset: int,
        Rsrvd: int,
        control_bits: int,
        flags: flag list,
        window: int,
        checksum: int,
        urgent_pointer: int
        (* options *)
    } 

    val toString : header -> string

    val verifyChecksum :
        {
            source_addr : int list, 
            dest_addr : int list
        } -> 
        header -> 
        int ->
        string ->
        bool

    val hasFlagsSet: int -> flag list -> bool

    val flagsToString : flag list -> string

    val decode : string -> header * string
    
    val encode : {
            source_addr : int list, 
            dest_addr : int list
        } -> {
            source_port : int,
            dest_port : int,
            sequence_number : int,
            ack_number : int,
            doffset : int,
            flags : flag list,
            window : int
        } -> string -> string
end

(*
    [flag] TCP control flags.

    [header] Contains the fields in a TCP header.

    [toString] Combines all the fields of a TCP header to easy printing. 

    [verifyChecksum] Verifies the checksum field for a given TCP packet.

    [hasFlagsSet] Checks whether the spceified control flags are set in the 
    given control bits field. 

    [flagsToString] Converts the flags to a human readable string.

    [decode] Decodes a string as a TCP header.

    [encode] Encode the fields of a TCP header to a string.
*)
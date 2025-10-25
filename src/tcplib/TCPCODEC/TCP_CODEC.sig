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
            total_length : int, 
            protocol : IPv4Codec.protocol, 
            source_addr : int list, 
            dest_addr : int list
        } -> 
        header -> 
        string -> 
        bool

    val decode : string -> header * string
    val encode : header -> string -> string
end

(*
[header] contains the fields in a TCP header.

[toString] combines all the fields of a TCP header to easy printing. 

[decode] decodes a string as a TCP header.

[encode] encode the fields of a TCP header to a string.
*)
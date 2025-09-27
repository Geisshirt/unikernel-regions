(*
    The TCPLib structure provides to de- and encode TCP headers.
*)

signature TCPLIB = sig
    datatype header = Header of {
        source_port: int,
        dest_port: int,
        sequence_number: int,
        ack_number: int,
        DOffset: int,
        Rsrvd: int,
        control_bits: int,
        window: int,
        checksum: int,
        urgent_pointer: int
    } 

    val toString : header -> string
    val decode : string -> header * string
    val encode : header -> string -> string
end

(*
[header] contains the fields in a TCP header.

[toString] combines all the fields of a TCP header to easy printing. 

[decode] decodes a string as a TCP header.

[encode] encode the fields of a TCP header to a string.
*)
(*
    The IPv4_CODEC structure provides useful functions for a ipv4 header.
*)

signature IPV4_CODEC = sig 
    type tl_protocol = int

    datatype header = Header of {
        version : int,
        ihl : int,
        dscp : int,
        ecn : int,
        total_length : int,
        identification : int,
        flags : int,
        fragment_offset : int,
        time_to_live : int,
        protocol : tl_protocol,
        header_checksum : int,
        source_addr : int list,
        dest_addr : int list
    }

    val isFragmented : header -> bool

    val toString : header -> string
    
    val decode : string -> header * string
    
    val encode : header -> string -> string
end 

(* 
    [header] IPv4 header representation (RFC 791).

    [isFragmented] Returns true if the IPv4 packet is fragmented as per the
    header.

    [toString] Produces a pretty printing string of the header.

    [decode] Decodes a string of bytes to an IPv4 header type.

    [encode] Encodes an IPv4 header as a string of bytes.
*)

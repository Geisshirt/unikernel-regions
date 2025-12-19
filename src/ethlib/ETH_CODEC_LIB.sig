(*
    The ETH_CODEC structure provides de- and encode functions of a ethernetframe header.
*)

signature ETH_CODEC = sig 
    datatype header = Header of { 
        ethType : Protocols.protocol, 
        dstMac : int list, 
        srcMac : int list
    }

    val bytesToEthType : string -> (Protocols.protocol option)
    val ethTypeToInt : Protocols.protocol -> int 
    val ethTypeToString : Protocols.protocol -> string

    val toString : header -> string
    val decode : string -> header * string
    val encode : header -> string -> string
end 

(*
    [bytesToEthType] converts a string to an ethType e.g. ARP.

    [ethTypeToInt] converts an ethType to an integer.

    [ethTypeToString] converts an ethType to a string for easy printing.

    [toString] combines all the fields of a ethernetframe header to easy printing. 

    [decode] decodes a string as a ethernetframe header.

    [encode] encode the fields of a ethernetframe header to a string.
*)
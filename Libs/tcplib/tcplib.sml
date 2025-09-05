(* TODO options *)
structure TCP : TCPLIB = struct
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
        (* options *)
    } 

    fun toString (Header {
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
    }) = 
        "\n-- TCP INFO --\n" ^
        "Source port: " ^ Int.toString source_port ^ "\n" ^
        "Destination port: " ^ Int.toString dest_port ^ "\n" ^
        "Sequence number: " ^ Int.toString sequence_number ^ "\n" ^
        "Acknowledgement number: " ^ Int.toString ack_number ^ "\n" ^
        "DOffset: " ^ Int.toString DOffset ^ "\n" ^
        "Reserved: " ^ Int.toString Rsrvd ^ "\n" ^
        "Control bits: " ^ Int.toString control_bits ^ "\n" ^
        "Window: " ^ Int.toString window ^ "\n" ^
        "Checksum: " ^ Int.toString checksum ^ "\n" ^
        "Urgent pointer: " ^ Int.toString urgent_pointer ^ "\n"

    fun decode s = (Header {
        source_port = String.substring(s, 0, 2) |> convertRawBytes,
        dest_port = String.substring(s, 2, 2) |> convertRawBytes,
        sequence_number =  String.substring(s, 4, 4) |> convertRawBytes,
        ack_number = String.substring(s, 8, 4) |> convertRawBytes,
        DOffset = getLBits (String.substring (s, 12, 1) |> convertRawBytes) 4,
        Rsrvd = getRBits (String.substring (s, 12, 1) |> convertRawBytes) 4,
        control_bits = String.substring(s, 13, 1) |> convertRawBytes,
        window = String.substring(s, 14, 2) |> convertRawBytes,
        checksum = String.substring(s, 16, 2) |> convertRawBytes,
        urgent_pointer = String.substring(s, 18, 2) |> convertRawBytes
    }, String.extract (s, 20, NONE))

    fun encode (Header { source_port, dest_port, sequence_number, 
                         ack_number, DOffset, Rsrvd, control_bits, 
                         window, checksum, urgent_pointer
    }) data =
        (intToRawbyteString source_port 2) ^
        (intToRawbyteString dest_port 2) ^
        (intToRawbyteString sequence_number 4) ^
        (intToRawbyteString ack_number 4) ^
        (intToRawbyteString (setLBits DOffset 4 + Rsrvd) 1) ^ 
        (intToRawbyteString control_bits 1) ^
        (intToRawbyteString window 2) ^
        (intToRawbyteString checksum 2) ^
        (intToRawbyteString urgent_pointer 2) ^
        data
end
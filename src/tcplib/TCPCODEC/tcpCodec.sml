(* TODO options *)
structure TcpCodec : TCP_CODEC = struct
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

    fun intToFlags i = 
        let fun andbi n m = Word8.andb (Word8.fromInt n, Word8.fromInt m) |> Word8.toInt in
            (if andbi i 0x80 <> 0 then [CWR] else []) @
            (if andbi i 0x40 <> 0 then [ECE] else []) @ 
            (if andbi i 0x20 <> 0 then [URG] else []) @ 
            (if andbi i 0x10 <> 0 then [ACK] else []) @
            (if andbi i 0x08 <> 0 then [PSH] else []) @
            (if andbi i 0x04 <> 0 then [RST] else []) @
            (if andbi i 0x02 <> 0 then [SYN] else []) @
            (if andbi i 0x01 <> 0 then [FIN] else [])
        end 
        
    fun flagToString flag =
        case flag of 
          FIN => "FIN"
        | SYN => "SYN"
        | RST => "RST"
        | PSH => "PSH"
        | ACK => "ACK"
        | URG => "URG"
        | ECE => "ECE"
        | CWR => "CWR"
            
    fun flagsToString flags = 
        let
          val flagList = List.map flagToString flags
        in
          case flagList of 
              [] => "Other"
            | _  => String.concatWith " | " flagList
        end

    fun encode (Header { source_port, dest_port, sequence_number, 
                         ack_number, DOffset, Rsrvd, control_bits, flags = _,
                         window, checksum, urgent_pointer
    }) data =
        (intToRawbyteString source_port 2) ^
        (intToRawbyteString dest_port 2) ^
        (intToRawbyteString sequence_number 4) ^
        (intToRawbyteString ack_number 4) ^
        (intToRawbyteString (setLBits DOffset 4) 1) ^ 
        (intToRawbyteString control_bits 1) ^
        (intToRawbyteString window 2) ^
        (intToRawbyteString checksum 2) ^
        (intToRawbyteString urgent_pointer 2) ^
        data

    fun verifyChecksum
        {
            total_length,
            protocol,
            source_addr,
            dest_addr
        }
        (Header {
            source_port,
            dest_port,
            sequence_number,
            ack_number,
            DOffset,
            Rsrvd,
            control_bits,
            flags,
            window,
            checksum,
            urgent_pointer
        }) 
        payload =
        let
            val tcpLength = total_length - 20
            val checksumHeader = 
                byteListToString source_addr ^
                byteListToString dest_addr ^ 
                intToRawbyteString 0 1 ^ (* Just zeros *)
                intToRawbyteString (IPv4Codec.protToInt protocol) 1 ^
                intToRawbyteString tcpLength 2 ^ 
                encode (Header {
                    source_port = source_port,
                    dest_port = dest_port,
                    sequence_number = sequence_number,
                    ack_number = ack_number,
                    DOffset = DOffset,
                    Rsrvd = Rsrvd,
                    control_bits = control_bits,
                    flags = flags,
                    window = window,
                    checksum = 0,
                    urgent_pointer = urgent_pointer
                }) payload ^
                (if tcpLength mod 8 <> 0 then intToRawbyteString 0 1 else "") 
            val computedChecksum : int = 
                checksumHeader |> toByteList |> toHextets |> makeChecksum
            
        in 
            print ("Checksum vs Computed: " ^ Int.toString checksum ^ " vs " ^ Int.toString computedChecksum);
            checksum = computedChecksum 
        end 


    fun toString (Header {
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
    }) = 
        "\n-- TCP INFO --\n" ^
        "Source port: " ^ Int.toString source_port ^ "\n" ^
        "Destination port: " ^ Int.toString dest_port ^ "\n" ^
        "Sequence number: " ^ Int.toString sequence_number ^ "\n" ^
        "Acknowledgement number: " ^ Int.toString ack_number ^ "\n" ^
        "DOffset: " ^ Int.toString DOffset ^ "\n" ^
        "Reserved: " ^ Int.toString Rsrvd ^ "\n" ^
        "Control bits: " ^ Int.toString control_bits ^ "\n" ^
        "Flags: " ^ flagsToString flags ^ "\n" ^
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
        flags = String.substring(s, 13, 1) |> convertRawBytes |> intToFlags,
        window = String.substring(s, 14, 2) |> convertRawBytes,
        checksum = String.substring(s, 16, 2) |> convertRawBytes,
        urgent_pointer = String.substring(s, 18, 2) |> convertRawBytes
    }, String.extract (s, 20, NONE))
end
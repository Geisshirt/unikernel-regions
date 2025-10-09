val header = {
        et=EthCodec.ARP, 
        dstMac = [133, 134, 135, 136, 137, 138], 
        srcMac = [123, 124, 125, 126, 127, 128]
}

val payload = "test payload"

val testRaw = 
    (byteListToString (#dstMac header)) ^
    (byteListToString (#srcMac header)) ^
    (intToRawbyteString 0x0806 2) ^
    payload

val () = (
    setTestSuiteName "Eth";
    
    printStart ();

    assert  ("ethTypeToInt ARP",
            (fn () => EthCodec.ethTypeToInt EthCodec.ARP),
            0x0806,
            Int.toString         
    );
    assert  ("ethTypeToInt IPv4",
            (fn () => EthCodec.ethTypeToInt EthCodec.IPv4),
            0x0800,
            Int.toString         
    );
    assert  ("ethTypeToInt IPv6",
            (fn () => EthCodec.ethTypeToInt EthCodec.IPv6),
            0x86dd,
            Int.toString         
    );

    assert  ("ethTypeToString ARP",
            (fn () => EthCodec.ethTypeToString EthCodec.ARP),
            "ARP",
            (fn s => s)         
    );
    assert  ("ethTypeToString IPv4",
            (fn () => EthCodec.ethTypeToString EthCodec.IPv4),
            "IPv4",
            (fn s => s)         
    );
    assert  ("ethTypeToString IPv6",
            (fn () => EthCodec.ethTypeToString EthCodec.IPv6),
            "IPv6",
            (fn s => s)         
    );

    assert  ("bytesToEthType ARP",
            (fn () => EthCodec.bytesToEthType "\u0008\u0006"),
            SOME (EthCodec.ARP),
            (fn SOME et => "SOME " ^ (EthCodec.ethTypeToString et) | NONE => "NONE")         
    );
    assert  ("bytesToEthType IPv4",
            (fn () => EthCodec.bytesToEthType "\u0008\u0000"),
            SOME (EthCodec.IPv4),
            (fn SOME et => "SOME " ^ (EthCodec.ethTypeToString et) | NONE => "NONE")         
    );
    assert  ("bytesToEthType IPv6",
            (fn () => EthCodec.bytesToEthType "\u0086\u00dd"),
            SOME (EthCodec.IPv6),
            (fn SOME et => "SOME " ^ (EthCodec.ethTypeToString et) | NONE => "NONE")         
    );
    assert  ("bytesToEthType IPv6",
            (fn () => EthCodec.bytesToEthType "\u0000\u0000"),
            NONE,
            (fn SOME et => "SOME " ^ (EthCodec.ethTypeToString et) | NONE => "NONE")         
    );

    assert  ("toString", 
            (fn () => EthCodec.toString (EthCodec.Header header)),
            ("\n-- ETHERFRAME INFO --\nType: ARP\nDestination mac-address: [ 133 134 135 136 137 138 ]\nSource mac-address: [ 123 124 125 126 127 128 ]\n"),
            (fn s => s));

    assert  ("decode", 
            (fn () => EthCodec.decode testRaw), 
            (EthCodec.Header header, payload),
            (fn (h, p) => "(" ^ (EthCodec.toString h) ^ ", " ^ p ^ ")"));
    
    assert  ("encode", 
            (fn () => EthCodec.encode (EthCodec.Header header) payload), 
            testRaw, 
            (rawBytesString o toByteList));

   assert  ("decode |> encode", 
            (fn () => EthCodec.decode testRaw |> (fn (h, p) => EthCodec.encode h p)), 
            testRaw,
            (rawBytesString o toByteList));
    
    assert  ("encode |> decode", 
            (fn () => EthCodec.encode (EthCodec.Header header) payload |> EthCodec.decode), 
            (EthCodec.Header header, payload), 
            (fn (h, p) => "(" ^ (EthCodec.toString h) ^ ", " ^ p ^ ")"));
        
    printResult ()
)

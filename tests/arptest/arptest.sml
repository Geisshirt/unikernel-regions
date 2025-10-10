val header = {
        htype = 1, 
        ptype = 0x0800, 
        hlen = 6, 
        plen = 4, 
        oper = ARPCodec.Reply, 
        sha = [123, 124, 125, 126, 127, 128], 
        spa = [10, 0, 0, 2], 
        tha = [123, 124, 125, 126, 127, 128], 
        tpa = [10, 0, 0, 2]
    }

val testRaw = 
    (intToRawbyteString (#htype header) 2) ^
    (intToRawbyteString (#ptype header) 2) ^
    (intToRawbyteString (#hlen header) 1) ^
    (intToRawbyteString (#plen header) 1) ^
    (intToRawbyteString 2 2) ^
    byteListToString (#sha header) ^
    byteListToString (#spa header) ^
    byteListToString (#tha header) ^
    byteListToString (#tpa header)

val () = (
    setTestSuiteName "ARP";
    
    printStart ();

    assert ("toArpOperation request",
        (fn () => ARPCodec.toArpOperation 1),
        (ARPCodec.Request),
        (fn x => ARPCodec.arpOperationToString x)
    );

    assert ("toArpOperation reply",
        (fn () => ARPCodec.toArpOperation 2),
        (ARPCodec.Reply),
        (fn x => ARPCodec.arpOperationToString x)
    );

    assert ("arpOperationToString request",
        (fn () => ARPCodec.arpOperationToString ARPCodec.Request),
        ("Request"),
        (fn s => s)
    );

    assert ("arpOperationToString reply",
        (fn () => ARPCodec.arpOperationToString ARPCodec.Reply),
        ("Reply"),
        (fn s => s)
    );

    assert ("arpOperationToInt request",
        (fn () => ARPCodec.arpOperationToInt ARPCodec.Request),
        (1),
        (fn x => x |> ARPCodec.toArpOperation |> ARPCodec.arpOperationToString)
    );

    assert ("arpOperationToInt reply",
        (fn () => ARPCodec.arpOperationToInt ARPCodec.Reply),
        (2),
        (fn x => x |> ARPCodec.toArpOperation |> ARPCodec.arpOperationToString)
    );

    assert ("toString",
        (fn () => ARPCodec.toString (ARPCodec.Header header)),
        ("\n-- ARP-packet --\nHardware type: 1\nProtocol type: 2048\nHardware address length: 6\nProtocol address length: 4\nOperation: Reply\nSender hardware address: [123 124 125 126 127 128]\nSender protocol address: [10 0 0 2]\nTarget hardware address: [123 124 125 126 127 128]\nTarget protocol address: [10 0 0 2]\n\n"),
        (fn s => s)
    );

    assert ("decode",
        (fn () => ARPCodec.decode testRaw),
        (ARPCodec.Header header),
        (fn (h) => ARPCodec.toString h)
    );

    assert ("encode",
        (fn () => ARPCodec.encode (ARPCodec.Header header)),
        testRaw,
        (rawBytesString o toByteList)
    );

    printResult ()
)

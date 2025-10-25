val header = {source_port=12345, dest_port=8080, length=20, checksum=0}

val wrongHeader = {source_port=12345, dest_port=8080, length=0, checksum=0}

val payload = "test payload"

val testRaw = 
    (intToRawbyteString (#source_port header) 2) ^
    (intToRawbyteString (#dest_port header) 2) ^
    (intToRawbyteString (#length header) 2) ^
    (intToRawbyteString (#checksum header) 2) ^ 
    payload

val () = (
    setTestSuiteName "UDP";
    
    printStart ();

    assert  ("toString", 
            (fn () => UdpCodec.toString (UdpCodec.Header header)),
            ("\n-- UDP INFO --\nSource port: 12345\nDestination port: 8080\nUDP length: 20\nChecksum: 0\n"),
            (fn s => s));

    assert  ("decode", 
            (fn () => UdpCodec.decode testRaw), 
            (UdpCodec.Header header, payload),
            (fn (h, p) => "(" ^ (UdpCodec.toString h) ^ ", " ^ p ^ ")"));
    
    assert  ("encode", 
            (fn () => UdpCodec.encode (UdpCodec.Header header) payload), 
            testRaw, 
            (rawBytesString o toByteList));

    assert  ("decode |> encode", 
            (fn () => UdpCodec.decode testRaw |> (fn (h, p) => UdpCodec.encode h p)), 
            testRaw,
            (rawBytesString o toByteList));
    
    assert  ("encode |> decode", 
            (fn () => UdpCodec.encode (UdpCodec.Header header) payload |> UdpCodec.decode), 
            (UdpCodec.Header header, payload), 
            (fn (h, p) => "(" ^ (UdpCodec.toString h) ^ ", " ^ p ^ ")"));

    (* Length is calculated independent of length value in header *)
    assert  ("encode with wrong header", 
            (fn () => UdpCodec.encode (UdpCodec.Header wrongHeader) payload), 
            testRaw, 
            (rawBytesString o toByteList));
    
    printResult ()
)

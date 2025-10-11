open Protocols

val header = {
        version = 4,
        ihl = 5,
        dscp = 0,
        ecn = 0,
        total_length = 32,
        identification = 50481,
        flags = 2,
        fragment_offset = 0,
        time_to_live = 64,
        protocol = UDP,
        header_checksum = 24985,
        source_addr = [10, 0, 0, 1],
        dest_addr = [10, 0, 0, 2]
    }

val headerFragmented = {
        version = 4,
        ihl = 5,
        dscp = 0,
        ecn = 0,
        total_length = 32,
        identification = 50481,
        flags = 1,
        fragment_offset = 0,
        time_to_live = 64,
        protocol = UDP,
        header_checksum = 24985,
        source_addr = [10, 0, 0, 1],
        dest_addr = [10, 0, 0, 2]
    }

val payload = "test payload" 

val testRaw = 
    intToRawbyteString (setLBits 4 4 + (#ihl header)) 1 ^ 
    intToRawbyteString (setLBits (#dscp header) 6 + (#ecn header)) 1 ^ 
    intToRawbyteString (32) 2 ^
    intToRawbyteString (#identification header) 2 ^
    intToRawbyteString ((setLBits (#flags header) 3 * (2 ** 8)) + (#fragment_offset header)) 2 ^
    intToRawbyteString (#time_to_live header) 1 ^
    intToRawbyteString ((#protocol header) |> IPv4Codec.protToInt) 1 ^ 
    intToRawbyteString 24985 2 ^
    byteListToString (#source_addr header) ^
    byteListToString (#dest_addr header) ^
    payload

val () = (
    setTestSuiteName "IPv4";
    
    printStart ();

    assert ("intToProt ICMP",
        (fn () => IPv4Codec.intToProt 0x01),
        (ICMP),
        (fn x => IPv4Codec.protToString x)
    );

    assert ("intToProt TCP",
        (fn () => IPv4Codec.intToProt 0x06),
        (TCP),
        (fn x => IPv4Codec.protToString x)
    );

    assert ("intToProt UDP",
        (fn () => IPv4Codec.intToProt 0x11),
        (UDP),
        (fn x => IPv4Codec.protToString x)
    );

    assert ("protToInt ICMP",
        (fn () => IPv4Codec.protToInt ICMP),
        (0x01),
        (Int.toString)
    );

    assert ("protToInt TCP",
        (fn () => IPv4Codec.protToInt TCP),
        (0x06),
        (Int.toString)
    );

    assert ("protToInt UDP",
        (fn () => IPv4Codec.protToInt UDP),
        (0x11),
        (Int.toString)
    );

    assert ("protToString ICMP",
        (fn () => IPv4Codec.protToString ICMP),
        ("ICMP"),
        (fn s => s)
    );

    assert ("protToString TCP",
        (fn () => IPv4Codec.protToString TCP),
        ("TCP"),
        (fn s => s)
    );

    assert ("protToString UDP",
        (fn () => IPv4Codec.protToString UDP),
        ("UDP"),
        (fn s => s)
    );

    assert ("isFragmented (no)",
        (fn () => IPv4Codec.isFragmented (IPv4Codec.Header header)),
        (false),
        (fn x => Bool.toString x)
    );

    assert ("isFragmented (yes)",
        (fn () => IPv4Codec.isFragmented (IPv4Codec.Header headerFragmented)),
        (true),
        (fn x => Bool.toString x)
    );

    assert ("toString",
        (fn () => IPv4Codec.toString (IPv4Codec.Header header)),
        ("\n-- IPV4 INFO --\nVersion: 4\nIHL: 5\nDSCP: 0\nECN: 0\nTotal length: 32\nIdentification: 50481\nFlags: 2\nFragment offset: 0\nTime to live: 64\nProtocol: UDP\nHeader checksum: 24985\nSRC-ADDRESS: 10 0 0 1\nDST-ADDRESS: 10 0 0 2\n"),
        (fn s => s)
    );
 
    assert ("decode",
        (fn () => IPv4Codec.decode testRaw),
        (IPv4Codec.Header header, payload),
        (fn (h, p) => (IPv4Codec.toString h) ^ ", " ^ p ^ ")")
    );

    assert ("encode",
        (fn () => IPv4Codec.encode (IPv4Codec.Header header) payload),
        testRaw,
        (rawBytesString o toByteList)
    );

    assert  ("decode |> encode", 
        (fn () => IPv4Codec.decode testRaw |> (fn (h, p) => IPv4Codec.encode h p)), 
        testRaw,
        (rawBytesString o toByteList)
    );

    assert  ("encode |> decode", 
        (fn () => IPv4Codec.encode (IPv4Codec.Header header) payload |> IPv4Codec.decode), 
        (IPv4Codec.Header header, payload), 
        (fn (h, p) => (IPv4Codec.toString h) ^ ", " ^ p ^ ")")
    );

    printResult ()
)


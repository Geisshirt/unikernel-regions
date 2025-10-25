structure IPv4Send :> IPV4_SEND = struct 
    val mtu = 1500

    fun send {ownMac, ownIPaddr, dstIPaddr, dstMac, identification, protocol, payload} =
        let val nfb = (mtu - 20) div 8
            fun sendFragments offset payload = 
                if String.size payload + 20 <= mtu 
                then 
                    (
                        Eth.send {
                            ownMac = ownMac,
                            dstMac = dstMac,
                            ethType = IPv4,
                            ethPayload = IPv4Codec.encode (IPv4Codec.Header {
                                    version = 4,                (* This is only for version 4 (ipv4) *)
                                    ihl = 5,                    (* Options are not allowed *)
                                    dscp = 0,                   (* Service class is standard *)
                                    ecn = 0,                    (* Not ECN capable *)
                                    total_length = 20 + (String.size payload),
                                    identification = identification,
                                    flags = 0,                  (* No more fragments *)                  
                                    fragment_offset = offset,
                                    time_to_live = 128,         (* Hard-coded time_to_live *)
                                    protocol = protocol,
                                    header_checksum = 0,        (* Will be calculated in encode *)  
                                    source_addr = ownIPaddr,
                                    dest_addr = dstIPaddr
                                }) payload
                        }
                    )
                else 
                    (Eth.send {
                        ownMac = ownMac,
                        dstMac = dstMac,
                        ethType = IPv4,
                        ethPayload = (
                            IPv4Codec.encode 
                                (IPv4Codec.Header {
                                    version = 4,                (* This is only for version 4 (ipv4) *)
                                    ihl = 5,                    (* Options are not allowed *)
                                    dscp = 0,                   (* Service class is standard *)
                                    ecn = 0,                    (* Not ECN capable *)
                                    total_length = 20 + (nfb * 8),
                                    identification = identification,
                                    flags = 1,                  (* More fragments *)                  
                                    fragment_offset = offset,
                                    time_to_live = 128,         (* Hard-coded time_to_live *)
                                    protocol = protocol,
                                    header_checksum = 0,        (* Will be calculated in encode *)  
                                    source_addr = ownIPaddr,
                                    dest_addr = dstIPaddr 
                                }) 
                                (String.substring (payload, 0, nfb * 8))
                        )
                    };
                    sendFragments (offset + nfb) (String.extract (payload, nfb*8, NONE)))
        in  sendFragments 0 payload
        end
end

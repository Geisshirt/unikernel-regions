signature PROTOCOLS = sig
    datatype protocol = ARP | IPv4 | IPv6 | UDP | TCP | ICMP | Other | UNKNOWN
end

structure Protocols : PROTOCOLS = struct
    datatype protocol = ARP | IPv4 | IPv6 | UDP | TCP | ICMP | Other | UNKNOWN
end
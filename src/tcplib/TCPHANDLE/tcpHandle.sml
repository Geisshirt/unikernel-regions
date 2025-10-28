open Logging
open Protocols

structure TcpHandle :> TCP_HANDLE = struct
    type port = int

    fun handl {bindings, ownMac, dstMac, ownIPaddr, dstIPaddr, ipv4Header, tcpPayload} =
        let val (TcpCodec.Header tcpHeader, tcpPayload) = tcpPayload |> TcpCodec.decode
            val binding = List.find (fn (port, cb) => (#dest_port tcpHeader) = port) bindings
            val IPv4Codec.Header ipv4Header = ipv4Header
            val payload = (
                case binding of
                  SOME (_, cb) => cb tcpPayload
                | NONE => "Port is not mapped to a function.\n"
            )
            val connection = TcpState.lookup {
                source_addr = #source_addr ipv4Header,
                dest_addr   = #dest_addr ipv4Header,
                source_port = #source_port tcpHeader,
                dest_port   = #dest_port tcpHeader
            }

        in  
            log TCP (TcpCodec.Header tcpHeader |> TcpCodec.toString) (SOME tcpPayload)
            (* if TcpCodec.verifyChecksum 
              {
                total_length = #total_length ipv4Header, 
                protocol = #protocol ipv4Header, 
                source_addr = #source_addr ipv4Header, 
                dest_addr = #dest_addr ipv4Header
              }
              (TcpCodec.Header tcpHeader)
              tcpPayload 
            then print "Verified!\n"
            else print "Not verified!\n" *)
            case (connection, #flags tcpHeader) of 
                (NONE, [TcpCodec.SYN]) => 
                    (* Add the connection and send SYN/ACK message. *)
                    () 

              | (SOME c, [TcpCodec.ACK]) =>
                    (* Update *)
                    ()

              | (SOME c, [TcpCodec.FIN]) =>
                    (* Update and send ACK*)
                    ()

              | _ => logMsg TCP "State combination not yet implemented."
        end
end

structure TcpHandle :> TCP_HANDLE = struct
    open Logging
    open Protocols

    type port = int

    fun handl {bindings, ownMac, dstMac, ownIPaddr, dstIPaddr, ipv4Header, tcpPayload} context =
        let val (TcpCodec.Header tcpHeader, tcpPayload) = tcpPayload |> TcpCodec.decode
            val binding = List.find (fn (port, cb) => (#dest_port tcpHeader) = port) bindings
            val IPv4Codec.Header ipv4Header = ipv4Header
            val payload = (
                case binding of
                  SOME (_, cb) => cb tcpPayload
                | NONE => "Port is not mapped to a function.\n"
            )
            val connection = 
                  TcpState.lookup {
                    source_addr = #source_addr ipv4Header,
                    source_port = #source_port tcpHeader,
                    dest_port   = #dest_port tcpHeader
                  } context
            
            val connection_id = {
                source_addr = #source_addr ipv4Header,
                source_port = #source_port tcpHeader,
                dest_port   = #dest_port tcpHeader
            }

        in  
            log TCP (TcpCodec.Header tcpHeader |> TcpCodec.toString) (SOME tcpPayload);
            (* if TcpCodec.verifyChecksum 
              {
                protocol = #protocol ipv4Header, 
                source_addr = #source_addr ipv4Header, 
                dest_addr = #dest_addr ipv4Header
              }
              (TcpCodec.Header tcpHeader)
              ((#total_length ipv4Header) - #ihl ipv4Header * 4)
              tcpPayload 
            then print "Verified!\n"
            else print "Not verified!\n"; *)
            case (connection, #flags tcpHeader) of 
                (NONE, [TcpCodec.SYN]) =>  (* Add the connection and send SYN/ACK message. *)
                  let
                    val newConn = TcpState.CON {
                      id = connection_id,
                      state = TcpState.SYN_REC,
                      sequence_number = 42, (* random number, not hardcoded? *)
                      ack_number = #sequence_number tcpHeader + 1
                    } 
                    val newContext = TcpState.add newConn context
                    val (TcpState.CON nc) = newConn
                    val tcpPayload = TcpCodec.encode {
                          protocol = Protocols.TCP,
                          source_addr = ownIPaddr,
                          dest_addr = dstIPaddr
                        } {
                          source_port = #dest_port tcpHeader,
                          dest_port = #source_port tcpHeader,
                          sequence_number = #sequence_number nc,
                          ack_number = #ack_number nc,
                          doffset = 20 div 4, (* 32-bit words *)
                          flags = [TcpCodec.SYN, TcpCodec.ACK],
                          window = #window tcpHeader
                        } ""
                  in
                    logMsg TCP "Recieved SYN, sending SYN/ACK.\n";
                    IPv4Send.send {
                        ownMac = ownMac,
                        ownIPaddr = ownIPaddr,
                        dstMac = dstMac,
                        dstIPaddr = dstIPaddr,
                        identification = (#identification ipv4Header), 
                        protocol = TCP, 
                        payload = tcpPayload
                    };
                    newContext
                  end
              | (SOME (TcpState.CON c), l) => 
                  (case (#state c, l) of 
                    (TcpState.SYN_REC, [TcpCodec.ACK]) => (
                      logMsg TCP "Recieved ACK on SYN/REC\n";
                      if #sequence_number c + 1 = #ack_number tcpHeader then 
                        (logMsg TCP "Recieved correct ACK, connection established\n"; 
                        TcpState.add (TcpState.CON {
                          id = connection_id, 
                          state = TcpState.ESTABLISHED, 
                          sequence_number = #sequence_number c, 
                          ack_number = #ack_number c}) context)
                      else 
                        (logMsg TCP "Recieved incorrect ACK\n";
                        context)
                      )
                  | (TcpState.ESTABLISHED, [TcpCodec.ACK]) => (
                     logMsg TCP "In established, recieved segment\n"; 
                     context
                    )
                  | _ => (
                    logMsg TCP "State combination not yet implemented.";
                    context
                  )) 
              | _ => (
                    logMsg TCP "State combination not yet implemented.";
                    context
                  )
        end
end
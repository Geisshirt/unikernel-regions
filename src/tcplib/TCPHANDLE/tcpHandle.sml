
structure TcpHandle :> TCP_HANDLE = struct
    open Logging
    open Protocols

    type port = int

    fun handl {bindings, ownMac, dstMac, ownIPaddr, dstIPaddr, ipv4Header, tcpPayload} context =
        let val (TcpCodec.Header tcpHeader, tcpPayload) = tcpPayload |> TcpCodec.decode
            val IPv4Codec.Header ipv4Header = ipv4Header
            val binding = List.find (fn (port, cb) => (#dest_port tcpHeader) = port) bindings
            val computedPayload  = (
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
            fun simpleSend {sequence_number : int, ack_number : int, flags : TcpCodec.flag list} payload =
              let val tcpPayload = TcpCodec.encode {
                          source_addr = ownIPaddr,
                          dest_addr = dstIPaddr
                        } {
                          source_port = #dest_port tcpHeader,
                          dest_port = #source_port tcpHeader,
                          sequence_number = sequence_number,
                          ack_number = ack_number,
                          doffset = 20 div 4, (* 32-bit words *)
                          flags = flags,
                          window = #window tcpHeader
                        } payload
              in IPv4Send.send {
                        ownMac = ownMac,
                        ownIPaddr = ownIPaddr,
                        dstMac = dstMac,
                        dstIPaddr = dstIPaddr,
                        identification = (#identification ipv4Header), 
                        protocol = TCP, 
                        payload = tcpPayload
                    }
              end
              
        in  
            log TCP (TcpCodec.Header tcpHeader |> TcpCodec.toString) (SOME tcpPayload);
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
                  in
                    logMsg TCP "Recieved SYN, sending SYN/ACK.\n";
                    simpleSend {
                      sequence_number = #sequence_number nc, 
                      ack_number = #ack_number nc, 
                      flags = [TcpCodec.SYN, TcpCodec.ACK]} 
                      "";
                    newContext
                  end
              | (SOME (TcpState.CON c), l) => 
                  (case (#state c, l) of 
                    (TcpState.SYN_REC, [TcpCodec.ACK]) => (
                      logMsg TCP "Recieved ACK on SYN/REC\n";
                      if #sequence_number c + 1 = #ack_number tcpHeader then 
                        (logMsg TCP "Recieved correct ACK, connection established\n"; 
                        TcpState.update (TcpState.CON {
                          id = connection_id, 
                          state = TcpState.ESTABLISHED, 
                          sequence_number = #sequence_number c + 1, 
                          ack_number = #ack_number c}) context)
                      else 
                        (logMsg TCP "Recieved incorrect ACK\n";
                        context)
                      )
                  | (TcpState.LAST_ACK, [TcpCodec.ACK]) => (
                      TcpState.remove connection_id context
                  )
                  | (TcpState.ESTABLISHED, [TcpCodec.FIN, TcpCodec.ACK]) => (
                      simpleSend 
                        {
                          sequence_number = #sequence_number c, 
                          ack_number = #ack_number c + 1, 
                          flags = [TcpCodec.ACK]
                        } 
                        "";
                      simpleSend 
                        {
                          sequence_number = #sequence_number c, 
                          ack_number = #ack_number c + 1, 
                          flags = [TcpCodec.FIN, TcpCodec.ACK]
                        } 
                        "";
                      TcpState.update (TcpState.CON {
                        id = connection_id, 
                        state = TcpState.LAST_ACK, 
                        sequence_number = #sequence_number c, 
                        ack_number = #ack_number c + 1}) context
                  )
                  | (TcpState.ESTABLISHED, flags) => (
                      logMsg TCP "In established, recieved segment\n"; 
                      if (TcpCodec.hasFlagsSet flags [TcpCodec.ACK]) then 
                        (simpleSend 
                          {
                            sequence_number = #sequence_number c, 
                            ack_number = #ack_number c + String.size tcpPayload, 
                            flags = [TcpCodec.ACK]
                          } 
                          computedPayload;
                        TcpState.update (TcpState.CON {
                          id = connection_id, 
                          state = TcpState.ESTABLISHED, 
                          sequence_number = #sequence_number c + String.size computedPayload, 
                          ack_number = #ack_number c + String.size tcpPayload}) context) 
                      else context
                    )
                  | _ => (
                    logMsg TCP "State combination not yet implemented.";
                    TcpState.print_states context;
                    #flags tcpHeader |> TcpCodec.flagsToString |> print;
                    context
                  )) 
              | _ => (
                    logMsg TCP "State combination not yet implemented.";
                    TcpState.print_states context;
                    #flags tcpHeader |> TcpCodec.flagsToString |> print;
                    context
                  )
        end
end
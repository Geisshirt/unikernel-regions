(* NOTE TO SELF: Remove print statements. *)

structure TcpHandle :> TCP_HANDLE = struct
    open Logging
    open Protocols
    open TcpState

    exception NotYetImplemented

    (* add sequence numbers *)
    fun +$(L1, L2) = (L1 + L2) mod (2 ** 32)
    infix 6 +$

    datatype notification = RESET

    type port = int

    fun handl {bindings, ownMac, dstMac, ownIPaddr, dstIPaddr, ipv4Header, tcpPayload} context =
        let val (TcpCodec.Header tcpHeader, tcpPayload) = tcpPayload |> TcpCodec.decode
            val IPv4Codec.Header ipv4Header = ipv4Header
            val binding = List.find (fn (port, cb) => (#dest_port tcpHeader) = port) bindings
            fun computePayload () = (
                  case binding of
                    SOME (_, cb) => cb tcpPayload
                  | NONE => "Port is not mapped to a function.\n"
            )
            fun notify (notification : notification) = ()
            val connection = 
                  lookup {
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
            val cbits = #control_bits tcpHeader
            fun check_sequence_number {sequence_number : int, segment_len : int} (RSV rsv) =
                if segment_len = 0 andalso (#wnd rsv) = 0 then (
                    print "FST CASE\n";
                    sequence_number = (#nxt rsv)
                )
                else if segment_len = 0 andalso (#wnd rsv) > 0 then (
                    print "SND CASE\n";
                    (#nxt rsv) <= sequence_number andalso sequence_number < (#nxt rsv + #wnd rsv) 
                )
                else if segment_len > 0 andalso (#wnd rsv) = 0 then (
                    print "THIRD CASE\n";
                    false
                )
                else (
                    "FOURTH CASE: " 
                    ^ ("(#nxt rsv) <= sequence_number - " ^ Bool.toString ((#nxt rsv) <= sequence_number) ^ "\n") 
                    ^ ("sequence_number < (#nxt rsv + #wnd rsv) - " ^ Bool.toString (sequence_number < (#nxt rsv + #wnd rsv)) ^ "\n") 
                    ^ ("(#nxt rsv) <= sequence_number + segment_len-1 - " ^ Bool.toString ((#nxt rsv) <= sequence_number + segment_len-1) ^ "\n") 
                    ^ ("sequence_number + segment_len-1 < (#nxt rsv + #wnd rsv) - " ^ Bool.toString (sequence_number + segment_len-1 < (#nxt rsv + #wnd rsv)) ^ "\n") 
                    |> print;
                    (#nxt rsv) <= sequence_number andalso sequence_number < (#nxt rsv + #wnd rsv)
                    orelse
                    (#nxt rsv) <= sequence_number + segment_len-1 andalso sequence_number + segment_len-1 < (#nxt rsv + #wnd rsv)
                )

        in  
            log TCP (TcpCodec.Header tcpHeader |> TcpCodec.toString) (SOME tcpPayload);
            case connection of 
                NONE => (* We are in "LISTEN" state. Section 3.10.7.2 in RFC 9293.*)
                    (if TcpCodec.hasFlagsSet cbits [TcpCodec.RST] then context
                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.ACK] then 
                        (simpleSend {
                            sequence_number = (#ack_number tcpHeader), 
                            ack_number = 0, 
                            flags = [TcpCodec.RST]} "";
                        context)
                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.SYN] then
                        let val iss = TcpState.new_iss ()
                            val newConn = CON {
                                id = connection_id,
                                state = SYN_REC,
                                send_seqvar = SSV {
                                    una = iss,
                                    nxt = iss +$ 1,
                                    wnd = 1,
                                    up = 0,
                                    wl1 = 0,
                                    wl2 = 0,
                                    iss = iss
                                },
                                receive_seqvar = RSV {
                                    nxt = (#sequence_number tcpHeader) +$ 1,
                                    wnd = 1,
                                    up  = 0,
                                    irs = #sequence_number tcpHeader
                                },
                                retran_queue = empty ()
                            }  
                        in
                        simpleSend {sequence_number = iss, 
                                    ack_number = ((#nxt o getRSV) newConn), 
                                    flags = [TcpCodec.SYN, TcpCodec.ACK]} "";  
                        TcpState.add newConn context 
                        end         
                    else context)
            |   SOME (CON con) =>
                    let 
                        fun seg_len () =
                            String.size tcpPayload
                            + (if TcpCodec.hasFlagsSet cbits [TcpCodec.SYN] then 1 else 0)
                            + (if TcpCodec.hasFlagsSet cbits [TcpCodec.FIN] then 1 else 0)
                            
                        fun valid () = check_sequence_number {sequence_number = #sequence_number tcpHeader, 
                                                              segment_len = seg_len ()} (#receive_seqvar con)
                        val ssv = getSSV (CON con)
                        val rsv = getRSV (CON con)
                    in
                        (* RCV.WND can only be zero for ACK, URG and RST *)
                        (* todo: RFC 5961 *)
                        (* todo: RFC 5961, section 5 *)
                        (* if (#state con) = SYN_SENT then context not implemented yet *)
                        (* urgent pointer not implemented *)
                        (* PSH flag is ignored - not implemented *)
                        (* We do not have segment buffer *)
                        (* retransmission when FIN *)
                        if not (valid ()) then (
                            "NOT VALID" ^ "\n" |> print;
                            if TcpCodec.hasFlagsSet cbits [TcpCodec.RST] then context
                            else 
                                (simpleSend {sequence_number = #nxt ssv, 
                                             ack_number = #nxt rsv, 
                                             flags = [TcpCodec.ACK]} "";
                                context)
                        )
                        else 
                            case (#state con) of 
                                SYN_REC => (
                                    "SYN_REC" ^ "\n" |> print;
                                    if TcpCodec.hasFlagsSet cbits [TcpCodec.RST] then 
                                       TcpState.remove connection_id context 
                                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.SYN] then 
                                        TcpState.remove connection_id context 
                                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.ACK] then
                                        if #una ssv < #ack_number tcpHeader andalso 
                                           #ack_number tcpHeader <= #nxt ssv then 
                                                let val newConn = CON {
                                                    id = connection_id,
                                                    state = ESTABLISHED,
                                                    send_seqvar = SSV {
                                                        una = #una ssv,
                                                        nxt = #nxt ssv,
                                                        wnd = #window tcpHeader,
                                                        up  = #up ssv,
                                                        wl1 = #sequence_number tcpHeader,
                                                        wl2 = #ack_number tcpHeader,
                                                        iss = #iss ssv
                                                    },
                                                    receive_seqvar = RSV {
                                                        nxt = #nxt rsv,
                                                        wnd = #window tcpHeader,
                                                        up = 0,
                                                        irs = #irs rsv

                                                    },
                                                    retran_queue = (#retran_queue con)
                                                }  
                                                in TcpState.update newConn context
                                                end
                                        else
                                            (simpleSend {
                                                sequence_number = #ack_number tcpHeader, 
                                                ack_number = 0, 
                                                flags = [TcpCodec.RST]} 
                                                "";
                                            context)
                                    else context
                                )
                            |   ESTABLISHED => (
                                    "ESTABLISHED" ^ "\n" |> print;
                                    if TcpCodec.hasFlagsSet cbits [TcpCodec.RST] then 
                                        (notify RESET;
                                        TcpState.remove connection_id context)
                                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.SYN] then 
                                        (notify RESET;
                                        TcpState.remove connection_id context)  
                                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.ACK] then
                                            let 
                                                val newUna =  
                                                        if  #una ssv < #ack_number tcpHeader andalso 
                                                            #ack_number tcpHeader <= #nxt ssv 
                                                        then #ack_number tcpHeader 
                                                        else #una ssv
                                                val (newSWnd, newSWl1, newSWl2) = 
                                                        if #wl1 ssv < #sequence_number tcpHeader orelse 
                                                           #wl1 ssv = #sequence_number tcpHeader andalso 
                                                           #wl2 ssv <= #ack_number tcpHeader
                                                        then (#window tcpHeader, #sequence_number tcpHeader, #ack_number tcpHeader)
                                                        else (#wnd ssv, #wl1 ssv, #wl2 ssv)
                                                val (newSNxt, computedPayload) =
                                                        if #sequence_number tcpHeader = #nxt rsv then 
                                                            let val p = computePayload () in (#nxt ssv + String.size p, p) end
                                                        else (#nxt ssv, "")
                                                val newRNxt = 
                                                        if #sequence_number tcpHeader = #nxt rsv then 
                                                         (
                                                            print "Advanced!\n";
                                                            (* check if payload is too large! *)
                                                            #nxt rsv + String.size tcpPayload
                                                        )
                                                        else (
                                                            print "Did not advance!\n";
                                                            #nxt rsv
                                                        )
                                                val newConn = CON {
                                                    id = connection_id,
                                                    state = if TcpCodec.hasFlagsSet cbits [TcpCodec.FIN] then CLOSE_WAIT else ESTABLISHED,
                                                    send_seqvar = SSV {
                                                        una = newUna,
                                                        nxt = newSNxt,
                                                        wnd = newSWnd,
                                                        up  = #up ssv,
                                                        wl1 = newSWl1,
                                                        wl2 = newSWl2,
                                                        iss = #iss ssv
                                                    },
                                                    receive_seqvar = RSV {
                                                        nxt = newRNxt,
                                                        wnd = #wnd rsv,
                                                        up = #up rsv,
                                                        irs = #irs rsv
                                                    },
                                                    retran_queue = (#retran_queue con)
                                                }
                                                val newContext = TcpState.update (TcpState.retran_dropacked (#ack_number tcpHeader) newConn) context
                                            in 
                                                if (#ack_number tcpHeader > #nxt ssv) then (* What ack to send? *)
                                                   (print "Send duplicate ACK\n";
                                                    simpleSend {
                                                    sequence_number = #nxt ssv, 
                                                    ack_number = #nxt rsv, 
                                                    flags = [TcpCodec.ACK]}
                                                    "";
                                                    context) 
                                                else (
                                                    print "Send back payload\n";
                                                    if #sequence_number tcpHeader = #nxt rsv then 
                                                        (simpleSend 
                                                        {
                                                            sequence_number = (#nxt o getSSV) (CON con), 
                                                            ack_number =  (#nxt o getRSV) newConn, 
                                                            flags = [TcpCodec.ACK]
                                                        } 
                                                        computedPayload;
                                                        (* retransmission queue! *)
                                                        newContext)
                                                    else newContext
                                                )
                                            end
                                    else context
                                )
                            |   CLOSE_WAIT => (
                                    "CLOSE_WAIT" ^ "\n" |> print;
                                    if TcpCodec.hasFlagsSet cbits [TcpCodec.RST] then 
                                        (notify RESET;
                                        TcpState.remove connection_id context)
                                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.SYN] then 
                                        (notify RESET;
                                        TcpState.remove connection_id context)   
                                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.ACK] then
                                        let 
                                            val newUna =  
                                                    if  #una ssv < #ack_number tcpHeader andalso 
                                                        #ack_number tcpHeader <= #nxt ssv 
                                                    then #ack_number tcpHeader 
                                                    else #una ssv
                                            val (newWnd, newWl1, newWl2) = 
                                                    if #wl1 ssv < #sequence_number tcpHeader orelse 
                                                        #wl1 ssv = #sequence_number tcpHeader andalso 
                                                        #wl2 ssv <= #ack_number tcpHeader
                                                    then (#window tcpHeader, #sequence_number tcpHeader, #ack_number tcpHeader)
                                                    else (#wnd ssv, #wl1 ssv, #wl2 ssv)
                                            val newConn = CON {
                                                id = connection_id,
                                                state = if (#retran_queue con) |> isEmpty then LAST_ACK else CLOSE_WAIT,
                                                send_seqvar = SSV {
                                                    una = newUna,
                                                    nxt = #nxt ssv,
                                                    wnd = newWnd,
                                                    up  = #up ssv,
                                                    wl1 = newWl1,
                                                    wl2 = newWl2,
                                                    iss = #iss ssv
                                                },
                                                receive_seqvar = RSV rsv,
                                                retran_queue = (#retran_queue con)
                                            }  
                                            in 
                                                if (#ack_number tcpHeader > #nxt ssv) then (* What ack to send? *)
                                                   simpleSend {
                                                    sequence_number = #nxt ssv, 
                                                    ack_number = #nxt rsv, 
                                                    flags = [TcpCodec.ACK]} 
                                                    "" 
                                                else ();
                                                TcpState.update (TcpState.retran_dropacked (#ack_number tcpHeader) newConn) context
                                            end
                                    else context
                                )
                            |   LAST_ACK => (
                                    "LAST_ACK" ^ "\n" |> print;
                                    if TcpCodec.hasFlagsSet cbits [TcpCodec.RST] then 
                                        TcpState.remove connection_id context
                                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.SYN] then 
                                        (notify RESET;
                                        TcpState.remove connection_id context)  
                                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.ACK] then
                                        TcpState.remove connection_id context
                                    else context
                                )
                    end
              
              
              
              
              
              
              
                  (* let
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
                  end *)
              (* | (SOME (TcpState.CON c), l) => 
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
                  ))  *)
              (* | _ => (
                    logMsg TCP "State combination not yet implemented. Current states:\n";
                    TcpState.print_states context;
                    #flags tcpHeader |> TcpCodec.flagsToString |> print;
                    context
                  ) *)
        end
end
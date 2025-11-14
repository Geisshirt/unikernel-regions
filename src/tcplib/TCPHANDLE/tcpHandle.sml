(* 
    TODO:
        1. Establish and close wait states basically do the same, make functions.
 *)


structure TcpHandle :> TCP_HANDLE = struct
    open Logging
    open Protocols
    open TcpState

    (* Add sequence numbers. *)
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
                  | NONE => "TCP port is not mapped to a function.\n"
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
                            window = 65535 mod (2 ** 32)
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
                    sequence_number = (#nxt rsv)
                )
                else if segment_len = 0 andalso (#wnd rsv) > 0 then (
                    (#nxt rsv) <= sequence_number andalso sequence_number < (#nxt rsv + #wnd rsv) 
                )
                else if segment_len > 0 andalso (#wnd rsv) = 0 then false
                else (
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
                                retran_queue = empty (),
                                dup_count = 0
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
                                                    retran_queue = (#retran_queue con),
                                                    dup_count = 0
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
                                                            (* check if payload is too large! *)
                                                            #nxt rsv +$ String.size tcpPayload
                                                        else 
                                                            #nxt rsv
                                                val newCon = ((CON {
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
                                                    retran_queue = (#retran_queue con),
                                                    dup_count = if newUna <> #una ssv then 0 else #dup_count con
                                                }) |> (TcpState.retran_dropacked (#ack_number tcpHeader)))
                                                val newContext = TcpState.update newCon context
                                                val rq = let val CON c = newCon in #retran_queue c end
                                            in 
                                                if (#ack_number tcpHeader > #nxt ssv) then (* What ack to send? *)
                                                   (simpleSend {
                                                    sequence_number = #nxt ssv, 
                                                    ack_number = #nxt rsv, 
                                                    flags = [TcpCodec.ACK]}
                                                    "";
                                                    context) 
                                                else (
                                                    if #sequence_number tcpHeader = #nxt rsv andalso String.size tcpPayload > 0 then 
                                                        (simpleSend 
                                                        {
                                                            sequence_number = (#nxt o getSSV) (CON con), 
                                                            ack_number =  (#nxt o getRSV) newCon, 
                                                            flags = [TcpCodec.ACK]
                                                        } 
                                                        computedPayload;
                                                        TcpState.update (TcpState.retran_enqueue {last_ack = newSNxt, payload = computedPayload} newCon) newContext)
                                                    else if #ack_number tcpHeader = newUna andalso String.size tcpPayload = 0 then (
                                                        if #dup_count con = 2 then (
                                                            case Queue.peek rq of 
                                                                NONE => newContext
                                                                (* TODO: Fix queue reordering *)
                                                            |   SOME ({last_ack, payload}, _) => (
                                                                    simpleSend 
                                                                    {
                                                                        sequence_number = last_ack - String.size payload, 
                                                                        ack_number =  (#nxt o getRSV) (CON con), 
                                                                        flags = [TcpCodec.ACK]
                                                                    } 
                                                                    payload;
                                                                    TcpState.update (TcpState.dup_reset newCon) newContext
                                                                )
                                                        )

                                                        else 
                                                            TcpState.update (TcpState.dup_inc newCon) newContext
                                                    )   
                                                    else newContext
                                                )
                                            end
                                    else context
                                )
                            |   CLOSE_WAIT => (
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
                                            val newCon = (CON {
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
                                                retran_queue = (#retran_queue con),
                                                dup_count = if newUna <> #una ssv then 0 else #dup_count con } |> TcpState.retran_dropacked (#ack_number tcpHeader)
                                            )
                                            val rq = let val CON c = newCon in #retran_queue c end
                                            in 
                                                if (#ack_number tcpHeader > #nxt ssv) then (* What ack to send? *)
                                                   simpleSend {
                                                    sequence_number = #nxt ssv, 
                                                    ack_number = #nxt rsv, 
                                                    flags = [TcpCodec.ACK]} 
                                                    "" 
                                                else ();
                                                if #ack_number tcpHeader = newUna andalso String.size tcpPayload = 0 then (
                                                        if #dup_count con = 2 then (
                                                            case Queue.peek rq of 
                                                                NONE =>  TcpState.update newCon context 
                                                                (* TODO: Fix queue reordering *)
                                                            |   SOME ({last_ack, payload}, _) => (
                                                                    simpleSend 
                                                                    {
                                                                        sequence_number = last_ack - String.size payload, 
                                                                        ack_number =  (#nxt o getRSV) (CON con), 
                                                                        flags = [TcpCodec.ACK]
                                                                    } 
                                                                    payload;
                                                                    TcpState.update (TcpState.dup_reset newCon) context
                                                                )
                                                        )

                                                        else 
                                                            TcpState.update (TcpState.dup_inc newCon) context
                                                    )
                                                else  
                                                    TcpState.update newCon context
                                            end
                                    else context
                                )
                            |   LAST_ACK => (
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
        end
end
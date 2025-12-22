functor TcpHandler(val service : Service.service) :> TRANSPORT_LAYER_HANDLER = struct
    open Logging
    open Protocols
    open TcpState
    open Service

    (* Add sequence numbers. *)
    fun +$(L1, L2) = (L1 + L2) mod (2 ** 32)
    infix 6 +$

    datatype notification = RESET

    type info = {
        ownMac     : int list,
        dstMac     : int list,
        ownIPaddr  : int list,
        dstIPaddr  : int list,
        ipv4Header : IPv4Codec.header,
        payload : string
    }

    val protocol_int = 0x06

    val protocol_string = "TCP"

    val mss = 1460

    type h_context = TcpState.tcp_states

    fun initContext () = TcpState.empty_states ()

    fun copyContext `[r1 r2] (context : h_context`r1) : h_context`r2 = TcpState.copy context

    fun handl ({ownMac, dstMac, ownIPaddr, dstIPaddr, ipv4Header, payload}) context =
        let val (TcpCodec.Header tcpHeader, optionList, tcpPayload) = payload |> TcpCodec.decode

            val IPv4Codec.Header ipv4Header = ipv4Header
            
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

            fun serviceType () = 
                case service (#dest_port tcpHeader, SETUP) of 
                    SETUP_STREAM => STREAM
                |   SETUP_FULL => FULL
                |   _ => FULL

            fun sendAck {sequence_number : int, ack_number : int, flags : TcpCodec.flag list} options =
                let val tcpPayload = TcpCodec.encode {
                            source_addr = ownIPaddr,
                            dest_addr = dstIPaddr
                        } {
                            source_port = #dest_port tcpHeader,
                            dest_port = #source_port tcpHeader,
                            sequence_number = sequence_number,
                            ack_number = ack_number,
                            flags = flags,
                            window = 65535 (* mod (2 ** 32) *)
                        } options ""
                in  IPv4Send.send {
                        ownMac = ownMac,
                        ownIPaddr = ownIPaddr,
                        dstMac = dstMac,
                        dstIPaddr = dstIPaddr,
                        identification = (#identification ipv4Header), 
                        protocol = protocol_int, 
                        payload = tcpPayload
                    }
                end
            
            fun sendSegment {sequence_number : int, ack_number : int, flags : TcpCodec.flag list} payload =
                let val tcpPayload = TcpCodec.encode {
                            source_addr = ownIPaddr,
                            dest_addr = dstIPaddr
                        } {
                            source_port = #dest_port tcpHeader,
                            dest_port = #source_port tcpHeader,
                            sequence_number = sequence_number,
                            ack_number = ack_number,
                            flags = flags,
                            window = 65535
                        } NONE payload
                in  IPv4Send.send {
                        ownMac = ownMac,
                        ownIPaddr = ownIPaddr,
                        dstMac = dstMac,
                        dstIPaddr = dstIPaddr,
                        identification = (#identification ipv4Header), 
                        protocol = protocol_int, 
                        payload = tcpPayload
                    }
                end
            
            fun sendQueuedSegments con = 
                let val ssv = getSSV con
                    val rsv = getRSV con
                in  if #mss ssv <= #una ssv +$ (#wnd ssv - #nxt ssv) then 
                        case send_dequeue con of 
                            SOME (payload, con) => 
                                let val sequence_number = #nxt ssv
                                    val ack_number = #nxt rsv
                                    val payloadSize = String.size payload
                                in 
                                    sendSegment {sequence_number = sequence_number, ack_number = ack_number, flags = [TcpCodec.ACK]} payload;
                                        retran_enqueue {last_ack = sequence_number +$ payloadSize, payload = payload} con  
                                    |>  update_sseqvar (SSV.update_nxt (fn nxt => nxt +$ payloadSize))
                                    |>  sendQueuedSegments
                                end 
                        |   NONE => con
                    else con
                end

            val cbits = #control_bits tcpHeader
            fun check_sequence_number {sequence_number : int, segment_len : int} (RSV rsv) =
                if segment_len = 0 andalso (#wnd rsv) = 0 then sequence_number = (#nxt rsv)
                else if segment_len = 0 andalso (#wnd rsv) > 0 then
                    (#nxt rsv) <= sequence_number andalso sequence_number < (#nxt rsv + #wnd rsv) 
                else if segment_len > 0 andalso (#wnd rsv) = 0 then false
                else (
                    (#nxt rsv) <= sequence_number andalso sequence_number < (#nxt rsv + #wnd rsv) orelse
                    (#nxt rsv) <= sequence_number + segment_len-1 andalso sequence_number + segment_len-1 < (#nxt rsv + #wnd rsv)
                )
            
            fun update_sequence_vars old_con = (
                    old_con
                |>  update_sseqvar (
                        SSV.update_una (fn una => 
                            let val nxt = (#nxt o getSSV) old_con in 
                                if  una < #ack_number tcpHeader andalso 
                                    #ack_number tcpHeader <= nxt
                                then #ack_number tcpHeader 
                                else una
                            end 
                    ))
                |>  (fn con =>
                        let val old_una = (#una o getSSV) old_con
                            val new_una = (#una o getSSV) con in
                            if old_una <> new_una 
                            then    
                                    dup_reset con
                                |>  retran_dropacked (#ack_number tcpHeader)
                            else con
                        end
                    )
                |>  update_sseqvar (fn SSV ssv => 
                        if  #wl1 ssv < #sequence_number tcpHeader orelse 
                            #wl1 ssv = #sequence_number tcpHeader andalso 
                            #wl2 ssv <= #ack_number tcpHeader 
                        then 
                               SSV ssv
                            |> SSV.update_wnd (fn _ => #window tcpHeader)
                            |> SSV.update_wl1 (fn _ => #sequence_number tcpHeader)
                            |> SSV.update_wl2 (fn _ => #ack_number tcpHeader) 
                        else SSV ssv
                    )
                |>  update_rseqvar (RSV.update_nxt (fn nxt => 
                        if #sequence_number tcpHeader = nxt 
                        then  
                            nxt 
                                +$ String.size tcpPayload 
                                +$ (if TcpCodec.hasFlagsSet cbits [TcpCodec.FIN] then 1 else 0)
                        else nxt
                    ))
            )
        
            fun sendRetransmissions (CON con) =
                (if #ack_number tcpHeader = (#una o getSSV) (CON con) andalso String.size tcpPayload = 0 then
                    (if #dup_count con = 3 then (
                        case Queue.peek (#retran_queue con) of 
                            NONE => (CON con)
                        |   SOME ({last_ack, payload}, _) => (
                                sendSegment 
                                {
                                    sequence_number = last_ack - String.size payload, 
                                    ack_number = (#nxt o getRSV) (CON con), 
                                    flags = [TcpCodec.ACK]
                                }
                                (String.extract(payload, 0, SOME (String.size payload div 2)));
                                sendSegment 
                                {
                                    sequence_number = last_ack - String.size payload + (String.size payload div 2), 
                                    ack_number = (#nxt o getRSV) (CON con), 
                                    flags = [TcpCodec.ACK]
                                } 
                                (String.extract(payload, (String.size payload div 2), NONE));
                                dup_reset (CON con)
                        ))
                    else 
                        dup_inc (CON con))
                else CON con)
        in  
            log TCP (TcpCodec.Header tcpHeader |> TcpCodec.toString) (SOME tcpPayload);
            case connection of 
                NONE => (* We are in "LISTEN" state. Section 3.10.7.2 in RFC 9293.*)
                    (if TcpCodec.hasFlagsSet cbits [TcpCodec.RST] then context
                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.ACK] then 
                        (sendAck {
                            sequence_number = (#ack_number tcpHeader), 
                            ack_number = 0, 
                            flags = [TcpCodec.RST]} NONE;
                        context)
                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.SYN] then
                        let val newCon = initCon {
                                connection_id = connection_id,
                                receive_init = (#sequence_number tcpHeader),
                                send_mss = (
                                    case List.find (fn opt => case opt of TcpCodec.MSS i => true | _ => false) optionList of 
                                        SOME (TcpCodec.MSS i) => i 
                                    |   _ => 536  
                                ) 
                            } 
                        in
                            sendAck {sequence_number = (#iss o getSSV) newCon, 
                                    ack_number = (#nxt o getRSV) newCon, 
                                    flags = [TcpCodec.SYN, TcpCodec.ACK]} (SOME [TcpCodec.MSS mss]);  
                            TcpState.add newCon context 
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
                        if not (valid ()) then (
                            if TcpCodec.hasFlagsSet cbits [TcpCodec.RST] then context
                            else 
                                (sendAck {  sequence_number = #nxt ssv, 
                                             ack_number = #nxt rsv, 
                                             flags = [TcpCodec.ACK]} NONE;
                                context)
                        )
                        else if TcpCodec.hasFlagsSet cbits [TcpCodec.RST] orelse 
                                TcpCodec.hasFlagsSet cbits [TcpCodec.SYN] then 
                            TcpState.remove connection_id context
                        else if TcpCodec.hasFlagsSet cbits [TcpCodec.ACK] then (
                            case (#state con) of 
                                SYN_REC => (
                                    if  #una ssv < #ack_number tcpHeader andalso 
                                        #ack_number tcpHeader <= #nxt ssv 
                                    then 
                                           CON con
                                        |> update_state (fn _ => ESTABLISHED)
                                        |> update_sseqvar (
                                                  SSV.update_wnd (fn _ => #window tcpHeader)
                                                o SSV.update_wl1 (fn _ => #sequence_number tcpHeader)
                                                o SSV.update_wl2 (fn _ => #ack_number tcpHeader)
                                            )
                                        |> update_rseqvar (
                                                RSV.update_wnd (fn _ => 65535)
                                        )
                                        |> update_service_type (fn _ => serviceType ())
                                        |> (fn con => TcpState.update con context)
                                    else
                                        (sendAck {
                                            sequence_number = #ack_number tcpHeader, 
                                            ack_number = 0, 
                                            flags = [TcpCodec.RST]} NONE;
                                        context)
                                )
                            |   LAST_ACK =>
                                    if #ack_number tcpHeader = #nxt ssv + 1 
                                    then TcpState.remove connection_id context
                                    else context
                            |   CLOSE_WAIT => (
                                    update_sequence_vars (CON con)
                                    |> (fn CON con => 
                                        let val ssv = getSSV (CON con)
                                            val rsv = getRSV (CON con)
                                        in
                                            if #ack_number tcpHeader > #nxt ssv then
                                                (sendAck {
                                                    sequence_number = #nxt ssv, 
                                                    ack_number = #nxt rsv, 
                                                    flags = [TcpCodec.ACK]} NONE;
                                                CON con)
                                            else if 
                                                    Queue.isEmpty (#retran_queue con) andalso 
                                                    Queue.isEmpty (#send_queue con) then
                                                (sendAck {
                                                    sequence_number = #nxt ssv, 
                                                    ack_number = #nxt rsv, 
                                                    flags = [TcpCodec.ACK, TcpCodec.FIN]} NONE;
                                                update_state (fn _ => LAST_ACK) (CON con))
                                            else CON con
                                        end)
                                    |> sendRetransmissions
                                    |> sendQueuedSegments
                                    |> (fn c => TcpState.update c context)
                                ) 
                            |   ESTABLISHED => (
                                        CON con
                                    |>  update_sequence_vars
                                    |>  update_state (fn s => 
                                            if TcpCodec.hasFlagsSet cbits [TcpCodec.FIN] andalso #sequence_number tcpHeader = #nxt rsv
                                            then CLOSE_WAIT 
                                            else s
                                        ) 
                                    |> (fn CON newCon => 
                                            if (#ack_number tcpHeader > #nxt ssv) 
                                            then 
                                                (sendAck {
                                                    sequence_number = #nxt ssv, 
                                                    ack_number = #nxt rsv, 
                                                    flags = [TcpCodec.ACK]} NONE;
                                                CON newCon)
                                            else if #sequence_number tcpHeader = #nxt rsv andalso 
                                                    ((String.size tcpPayload > 0) orelse (TcpCodec.hasFlagsSet cbits [TcpCodec.FIN])) andalso
                                                    (#service_type con = STREAM orelse (#service_type con = FULL andalso #state newCon = CLOSE_WAIT)) 
                                            then
                                                let val (requestPayload, CON newCon) = 
                                                        case #service_type con of 
                                                            FULL   =>  CON newCon |> rec_enqueue tcpPayload |> rec_collect
                                                        |   STREAM => (tcpPayload, CON newCon)
                                                        
                                                in 
                                                    case service (#dest_port tcpHeader, REQUEST requestPayload) of 
                                                        REPLY payload => send_enqueue_many payload (CON newCon)
                                                    |   _ => CON newCon
                                                end
                                            else if #service_type con = FULL andalso 
                                                    #sequence_number tcpHeader = #nxt rsv andalso 
                                                    String.size tcpPayload > 0 
                                            then
                                                (sendAck {
                                                    sequence_number = (#nxt o getSSV) (CON newCon), 
                                                    ack_number = (#nxt o getRSV) (CON newCon), 
                                                    flags = [TcpCodec.ACK]} NONE;  
                                                rec_enqueue tcpPayload (CON newCon)) 
                                            else CON newCon)
                                    |> sendRetransmissions
                                    |> sendQueuedSegments
                                    |> (fn c => TcpState.update c context)
                                )
                        ) else context
                    end
        end
end

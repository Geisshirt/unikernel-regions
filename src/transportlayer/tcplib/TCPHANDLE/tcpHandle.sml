(*
    TODO:
        1. Establish and close wait states basically do the same, make functions.
        2. Implement proper ISN
        3. Window size
 *)

functor TcpHandler(val service : Service.service) :> TRANSPORT_LAYER_HANDLER = struct
    open Logging
    open Protocols
    open TcpState
    open Service

    (* Add sequence numbers. *)
    fun +$(L1, L2) = (L1 + L2) mod (2 ** 32)
    infix 6 +$

    infix 3 |> fun x |> f = f x

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

    val mss = 536

    type h_context = TcpState.tcp_states

    fun initContext () = TcpState.empty_states ()

    fun copyContext `[r1 r2] (context : h_context`r1) : h_context`r2 = TcpState.copy context

    fun handl ({ownMac, dstMac, ownIPaddr, dstIPaddr, ipv4Header, payload}) context =
        let val (TcpCodec.Header tcpHeader, tcpPayload) = payload |> TcpCodec.decode
            val IPv4Codec.Header ipv4Header = ipv4Header
            val send_mss = 536
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

            fun sendAck {sequence_number : int, ack_number : int, flags : TcpCodec.flag list} =
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
                            window = 65535 (* mod (2 ** 32) *)
                        } ""
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
(* {
    sequence_number = (#nxt o getSSV) (CON newCon),
    ack_number = (#nxt o getRSV) (CON newCon), 
    flags = [TcpCodec.ACK]
} *)
            
            fun sendSegment {sequence_number : int, ack_number : int, flags : TcpCodec.flag list} payload =
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
                            window = 65535
                        } payload
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
                        (case send_dequeue con of 
                            SOME (payload, con) => 
                                let val sequence_number = #nxt ssv
                                    val ack_number = #nxt rsv
                                in 
                                    sendSegment {sequence_number = sequence_number, ack_number = ack_number, flags = [TcpCodec.ACK]} payload;
                                    (retran_enqueue {last_ack = sequence_number +$ String.size payload, payload = payload} con |> 
                                    update_sseqvar (fn SSV ssv' => SSV {
                                                                        una = #una ssv',
                                                                        nxt = #nxt ssv' +$ String.size payload,
                                                                        wnd = #wnd ssv',
                                                                        up  = #up ssv',
                                                                        wl1 = #wl1 ssv',
                                                                        wl2 = #wl2 ssv',
                                                                        mss = #mss ssv',
                                                                        iss = #iss ssv'
                                                                    }) |> 
                                    sendQueuedSegments)
                                end 
                        |   NONE => (con))
                    else con
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
                        (sendAck {
                            sequence_number = (#ack_number tcpHeader), 
                            ack_number = 0, 
                            flags = [TcpCodec.RST]};
                        context)
                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.SYN] then
                        let val iss = TcpState.new_iss ()
                            val serviceType = 
                                (case service (#dest_port tcpHeader, SETUP) of 
                                    SETUP_STREAM => STREAM
                                |   SETUP_FULL => FULL
                                |   _ => FULL)
                            val newConn = CON {
                                id = connection_id,
                                state = SYN_REC,
                                send_seqvar = SSV {
                                    una = iss,
                                    nxt = iss +$ 1,
                                    wnd = 1,
                                    up  = 0,
                                    wl1 = 0,
                                    wl2 = 0,
                                    mss = send_mss,
                                    iss = iss
                                },
                                send_queue = Queue.empty (),
                                receive_seqvar = RSV {
                                    nxt = (#sequence_number tcpHeader) +$ 1,
                                    wnd = 1,
                                    up  = 0,
                                    irs = #sequence_number tcpHeader
                                },
                                receive_queue = "",
                                retran_queue = Queue.empty (),
                                dup_count = 0,
                                service_type = serviceType
                            }  
                        in
                        sendAck {sequence_number = iss, 
                                 ack_number = ((#nxt o getRSV) newConn), 
                                 flags = [TcpCodec.SYN, TcpCodec.ACK]};  
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
                                (sendAck {sequence_number = #nxt ssv, 
                                             ack_number = #nxt rsv, 
                                             flags = [TcpCodec.ACK]};
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
                                                        mss = send_mss,
                                                        iss = #iss ssv
                                                    },
                                                    send_queue = Queue.empty (),
                                                    receive_seqvar = RSV {
                                                        nxt = #nxt rsv,
                                                        wnd = #window tcpHeader,
                                                        up = 0,
                                                        irs = #irs rsv
                                                    },
                                                    receive_queue = "",
                                                    retran_queue = #retran_queue con,
                                                    dup_count = 0,
                                                    service_type = #service_type con
                                                }  
                                                in TcpState.update newConn context
                                                end
                                        else
                                            (sendAck {
                                                sequence_number = #ack_number tcpHeader, 
                                                ack_number = 0, 
                                                flags = [TcpCodec.RST]};
                                            context)
                                    else context
                                )
                            |   LAST_ACK => (
                                    if TcpCodec.hasFlagsSet cbits [TcpCodec.RST] then 
                                        TcpState.remove connection_id context
                                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.SYN] then 
                                        TcpState.remove connection_id context
                                    else if TcpCodec.hasFlagsSet cbits [TcpCodec.ACK] andalso #sequence_number tcpHeader = #nxt ssv + 1  then
                                        (   print "Removing connnection\n"; 
                                            let val newConnection = TcpState.remove connection_id context in
                                                List.length context |> Int.toString |> print; 
                                                "\n" |> print; 
                                                List.length newConnection |> Int.toString |> print; 
                                                "\n" |> print;
                                                newConnection
                                            end )
                                    else context
                                )
                            |   open_state => (
                                    if TcpCodec.hasFlagsSet cbits [TcpCodec.RST] orelse TcpCodec.hasFlagsSet cbits [TcpCodec.SYN] then 
                                        TcpState.remove connection_id context
                                    else if not (TcpCodec.hasFlagsSet cbits [TcpCodec.ACK]) then context
                                    else 
                                        let val newCon = (
                                            update_sseqvar (fn SSV ssv' => SSV {
                                                una = if #una ssv' < #ack_number tcpHeader andalso 
                                                         #ack_number tcpHeader <= #nxt ssv' 
                                                      then #ack_number tcpHeader 
                                                      else #una ssv',
                                                nxt = #nxt ssv',
                                                wnd = #wnd ssv',
                                                up  = #up ssv',
                                                wl1 = #wl1 ssv',
                                                wl2 = #wl2 ssv',
                                                mss = #mss ssv',
                                                iss = #iss ssv'
                                            }) (CON con) |>
                                            (fn CON newCon =>
                                                if (#una o getSSV) (CON con) <> (#una o getSSV) (CON newCon) 
                                                then dup_reset (CON newCon)
                                                     |> retran_dropacked (#ack_number tcpHeader)
                                                else CON newCon
                                            ) |>
                                            update_sseqvar (fn SSV ssv' => 
                                                if #wl1 ssv < #sequence_number tcpHeader orelse 
                                                   #wl1 ssv = #sequence_number tcpHeader andalso 
                                                   #wl2 ssv <= #ack_number tcpHeader then 
                                                    SSV {
                                                        una = #una ssv',
                                                        nxt = #nxt ssv',
                                                        wnd = #window tcpHeader,
                                                        up  = #up ssv',
                                                        wl1 = #sequence_number tcpHeader,
                                                        wl2 = #ack_number tcpHeader,
                                                        mss = #mss ssv',
                                                        iss = #iss ssv'
                                                    } 
                                                else SSV ssv'
                                            ) |>
                                            update_rseqvar (fn RSV rsv' => 
                                                if #sequence_number tcpHeader = #nxt rsv' then 
                                                    RSV {
                                                        nxt = #nxt rsv' +$ String.size tcpPayload + (if TcpCodec.hasFlagsSet cbits [TcpCodec.FIN] then 1 else 0),
                                                        wnd = #wnd rsv',
                                                        up = #up rsv',
                                                        irs = #irs rsv'
                                                    }
                                                else RSV rsv'
                                            ) |> 
                                            update_state (fn s => 
                                                if TcpCodec.hasFlagsSet cbits [TcpCodec.FIN] then ((Int.toString (#sequence_number tcpHeader)) ^ " " ^ (Int.toString (#nxt rsv))|> print; CLOSE_WAIT) else s
                                            ) |>
                                            (fn CON newCon => 
                                                (print "Starting connection\n"; if (#ack_number tcpHeader > #nxt ssv) then
                                                    effect (sendAck {
                                                        sequence_number = #nxt ssv, 
                                                        ack_number = #nxt rsv, 
                                                        flags = [TcpCodec.ACK]}) (CON newCon)
                                                else if open_state = CLOSE_WAIT andalso Queue.isEmpty (#retran_queue newCon) andalso Queue.isEmpty (#send_queue newCon) then 
                                                    (effect (sendAck {
                                                        sequence_number = #nxt ssv, 
                                                        ack_number = #nxt rsv, 
                                                        flags = [TcpCodec.ACK, TcpCodec.FIN]}) (CON newCon) |> 
                                                     update_state (fn _ => LAST_ACK))
                                                else if open_state = ESTABLISHED andalso
                                                    #sequence_number tcpHeader = #nxt rsv andalso ((String.size tcpPayload > 0) orelse (TcpCodec.hasFlagsSet cbits [TcpCodec.FIN])) andalso
                                                    (#service_type con = STREAM orelse (#service_type con = FULL andalso #state newCon = CLOSE_WAIT)) then
                                                    (print "going to close_wait\n";
                                                        let val (requestPayload, CON newCon) = 
                                                                (print "Collecting...\n";
                                                                case #service_type con of 
                                                                    FULL   => rec_collect (CON newCon |> rec_enqueue tcpPayload)
                                                                |   STREAM => (tcpPayload, CON newCon)
                                                                )
                                                        in 
                                                            let val con = (print "Running service...\n";
                                                                case service (#dest_port tcpHeader, REQUEST requestPayload) of 
                                                                REPLY payload => 
                                                                    (* TODO do not use sendsegment*)
                                                                    (print "Queing in send...\n";
                                                                    (send_enqueue_many 
                                                                        payload
                                                                        (CON newCon)))
                                                            |   _ => CON newCon)
                                                            in  print "Done2\n";
                                                                con 
                                                            end 
                                                        end)
                                                else if #ack_number tcpHeader = (#una o getSSV) (CON newCon) andalso String.size tcpPayload = 0 then
                                                    (if #dup_count newCon = 3 then (
                                                        case Queue.peek (#retran_queue newCon) of 
                                                            NONE => (CON newCon)
                                                        |   SOME ({last_ack, payload}, _) => (
                                                                sendSegment 
                                                                {
                                                                    sequence_number = last_ack - String.size payload, 
                                                                    ack_number = (#nxt o getRSV) (CON newCon), 
                                                                    flags = [TcpCodec.ACK]
                                                                }
                                                                (String.extract(payload, 0, SOME (String.size payload div 2)));
                                                                sendSegment 
                                                                {
                                                                    sequence_number = last_ack - String.size payload + (String.size payload div 2), 
                                                                    ack_number = (#nxt o getRSV) (CON newCon), 
                                                                    flags = [TcpCodec.ACK]
                                                                } 
                                                                (String.extract(payload, (String.size payload div 2), NONE));
                                                                dup_reset (CON newCon)
                                                        ))
                                                    else 
                                                        dup_inc (CON newCon))
                                                else if open_state = ESTABLISHED andalso #sequence_number tcpHeader = #nxt rsv andalso String.size tcpPayload > 0 andalso #service_type con = FULL then
                                                    (effect (sendAck {
                                                        sequence_number = (#nxt o getSSV) (CON newCon), 
                                                        ack_number = (#nxt o getRSV) (CON newCon), 
                                                        flags = [TcpCodec.ACK]}) (CON newCon) |>   
                                                    rec_enqueue tcpPayload) 
                                                else CON newCon)
                                            )
                                        )
                                        in  let val newCon' = TcpState.update (sendQueuedSegments newCon) context in
                                                print "Completely done\n";
                                                newCon'
                                            end 
                                        end
                                )
                    end
        end
end
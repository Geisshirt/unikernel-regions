structure TcpState : TCP_STATE = struct
    open Queue
    open Connection

    type tcp_states = connection list

    fun effect effectfun con = (effectfun; con)

    fun empty_states `[r1 r2 r3 r4 r5] () : connection`[r2 r3 r4 r5] list`[r1] = []

    fun new_iss () = 0

    fun compareIDs (cid1 : connection_id, cid2 : connection_id) : bool =
        #source_addr cid1 = #source_addr cid2 andalso
        #source_port cid1 = #source_port cid2 andalso
        #dest_port cid1   = #dest_port cid2

    fun initCon {
        connection_id : connection_id,
        receive_init : int,
        send_mss : int
    } = 
        let val iss = new_iss () in
            CON {
                id = connection_id,
                state = SYN_REC,
                send_seqvar = SSV {
                    una = iss,
                    nxt = iss + 1,
                    wnd = 1,
                    up  = 0,
                    wl1 = 0,
                    wl2 = 0,
                    mss = send_mss,
                    iss = iss
                },
                send_queue = Queue.empty (),
                receive_seqvar = RSV {
                    nxt = receive_init + 1,
                    wnd = 1,
                    up  = 0,
                    irs = receive_init
                },
                receive_queue = "",
                retran_queue = Queue.empty (),
                dup_count = 0,
                service_type = FULL
            } 
        end

    fun copyConnection (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type} : connection) : connection =
        let fun copyListI [] = []
              | copyListI (x::xr) = x :: copyListI xr
            fun copyID ({
                source_addr,
                source_port,
                dest_port
            }) = {
                source_addr = copyListI source_addr,
                source_port = source_port,
                dest_port = dest_port
            }
            fun copySSV (SSV {
                una,
                nxt,
                wnd,
                up,
                wl1,
                wl2,
                mss,
                iss
            }) = SSV {
                una = una,
                nxt = nxt,
                wnd = wnd,
                up = up,
                wl1 = wl1,
                wl2 = wl2,
                mss = mss,
                iss = iss
            }
            fun copyRSV (RSV {
                nxt,
                wnd,
                up,
                irs
            }) = RSV {
                nxt = nxt,
                wnd = wnd,
                up = up,
                irs = irs
            }
            fun copyListS [] = []
              | copyListS (x::xr) = x ^ "" :: copyListS xr
            fun copyQueueS ((front, back)) =
                    (copyListS front, copyListS back)
            fun copyListR [] = []
              | copyListR ({last_ack, payload}::xr) = {last_ack = last_ack, payload = payload ^ ""} :: copyListR xr
            fun copyQueueR ((front, back)) =
                    (copyListR front, copyListR back)
        in (
            CON {
               id = copyID id,
               state = state,
               send_seqvar = copySSV send_seqvar,
               send_queue = copyQueueS send_queue,
               receive_seqvar = copyRSV receive_seqvar,
               receive_queue = receive_queue ^ "",
               retran_queue = copyQueueR retran_queue,
               dup_count = dup_count,
               service_type = service_type
            }
        ) end

    fun copy (states : tcp_states) : tcp_states =
        let fun copyList [] = []
              | copyList (x::xr) = copyConnection x :: copyList xr
        in
            copyList states
        end

    fun lookup (cid : connection_id) states : connection option =
        List.find (fn (CON c : connection) => compareIDs (#id c, cid)) states

    fun add (conn : connection) (states : tcp_states) : tcp_states =
        conn :: states

    fun update (CON conn : connection) (states : tcp_states) : tcp_states =
        List.map (fn (CON c : connection) => if compareIDs (#id c, #id conn) then CON conn else CON c) states

    fun remove (cid : connection_id) (states : tcp_states) : tcp_states =
        List.filter (fn (CON c : connection) => not (compareIDs (#id c, cid))) states

    fun print_states (states : tcp_states) : unit =
        List.app (fn (CON c : connection) =>
            let
                val sAdd = String.concatWith "." (List.map Int.toString (#source_addr (#id c)))
                val sPort = Int.toString (#source_port (#id c))
                val dPort = Int.toString (#dest_port (#id c))
                val stateStr = (case #state c of
                                    ESTABLISHED => "ESTABLISHED"
                                    | SYN_REC     => "SYN RECEIVED"
                                    | LAST_ACK    => "LAST ACK"
                                    | CLOSE_WAIT => "CLOSE WAIT")
                val out = "From: " ^ sAdd ^ ":" ^ sPort ^
                    "\nTo: " ^ dPort ^
                    "\nState: " ^ stateStr ^ "\n\n"
            in
                print out
            end)
        states
end

structure TcpState : TCP_STATE = struct
    open Queue

    datatype service_type = STREAM | FULL

    datatype tcp_state = ESTABLISHED | SYN_REC | CLOSE_WAIT | LAST_ACK

    type connection_id = {
        source_addr : int list,
        source_port : int,
        dest_port   : int
    }

    datatype send_seqvar = SSV of {
        una : int,
        nxt : int,
        wnd : int,
        up  : int,
        wl1 : int,
        wl2 : int,
        mss : int,
        iss : int
    }

    datatype receive_seqvar = RSV of {
        nxt : int,
        wnd : int,
        up  : int,
        irs : int 
    }

    datatype connection = CON of {
        id             : connection_id,
        state          : tcp_state,
        send_seqvar    : send_seqvar,
        send_queue     : string queue,
        receive_seqvar : receive_seqvar,
        receive_queue  : string queue,
        retran_queue   : {last_ack : int, payload : string} queue,
        dup_count      : int,
        service_type   : service_type
    }

    fun effect effectfun con = (effectfun; con)

    fun update_state statefun (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) = (
        CON {
            id = id,
            state = statefun state,
            send_seqvar = send_seqvar,
            send_queue = send_queue,
            receive_seqvar = receive_seqvar,
            receive_queue = receive_queue,
            retran_queue = retran_queue,
            dup_count = dup_count,
            service_type = service_type
        } 
    ) 

    fun update_sseqvar ssvfun (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) = (
        CON {
            id = id,
            state = state,
            send_seqvar = ssvfun send_seqvar,
            send_queue = send_queue,
            receive_seqvar = receive_seqvar,
            receive_queue = receive_queue,
            retran_queue = retran_queue,
            dup_count = dup_count,
            service_type = service_type
        } 
    )

    fun update_rseqvar rsvfun (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type})  = (
        CON {
            id = id,
            state = state,
            send_seqvar = send_seqvar,
            send_queue = send_queue,
            receive_seqvar = rsvfun receive_seqvar,
            receive_queue = receive_queue,
            retran_queue = retran_queue,
            dup_count = dup_count,
            service_type = service_type
        } 
    )

    fun dup_inc (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) = (
        CON {
            id = id,
            state = state,
            send_seqvar = send_seqvar,
            send_queue = send_queue,
            receive_seqvar = receive_seqvar,
            receive_queue = receive_queue,
            retran_queue = retran_queue,
            dup_count = dup_count + 1,
            service_type = service_type
        }  
    ) 

    fun dup_reset (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count = _, service_type}) = (
        CON {
            id = id,
            state = state,
            send_seqvar = send_seqvar,
            send_queue = send_queue,
            receive_seqvar = receive_seqvar,
            receive_queue = receive_queue,
            retran_queue = retran_queue,
            dup_count = 0,
            service_type = service_type
        }  
    )

    fun retran_enqueue {last_ack, payload} (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) =
        let
            val entry = {last_ack = last_ack, payload = payload}
            val new_q = enqueue (entry, retran_queue)
        in
            CON {
                id = id,
                state = state,
                send_seqvar = send_seqvar,
                send_queue = send_queue,
                receive_seqvar = receive_seqvar,
                receive_queue = receive_queue,
                retran_queue = new_q,
                dup_count = dup_count,
                service_type = service_type
            }  
        end

    fun send_enqueue_many payload (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) =
        let
            val SSV ssv = send_seqvar
            val mss = #mss ssv
            val ended = String.size payload
            fun makeSegments start q =
                if ended-start <= mss then 
                    enqueue (substring (payload, start, ended-start), q)
                else 
                    enqueue (substring (payload, start, mss), q) |> 
                    makeSegments (start+mss)
        in
            CON {
                id = id,
                state = state,
                send_seqvar = send_seqvar,
                send_queue = makeSegments 0 send_queue,
                receive_seqvar = receive_seqvar,
                receive_queue = receive_queue,
                retran_queue = retran_queue,
                dup_count = dup_count,
                service_type = service_type
            }  
        end

    fun send_dequeue (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) =
        case dequeue send_queue of 
            SOME (p, q) =>
                SOME (p,
                    CON {
                        id = id,
                        state = state,
                        send_seqvar = send_seqvar,
                        send_queue = q,
                        receive_seqvar = receive_seqvar,
                        receive_queue = receive_queue,
                        retran_queue = retran_queue,
                        dup_count = dup_count,
                        service_type = service_type
                    })
        |   NONE => NONE

    fun send_is_empty (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) =
        Queue.isEmpty send_queue

    fun rec_enqueue payload (CON {id, state, send_seqvar, send_queue, receive_seqvar,receive_queue, retran_queue, dup_count, service_type}) =
        let
            val new_q = enqueue (payload, receive_queue)
        in
            CON {
                id = id,
                state = state,
                send_seqvar = send_seqvar,
                send_queue = send_queue,
                receive_seqvar = receive_seqvar,
                receive_queue = new_q,
                retran_queue = retran_queue,
                dup_count = dup_count,
                service_type = service_type
            }  
        end

    fun rec_collect (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) = 
        (Queue.toList receive_queue |> List.rev |> foldl (op ^) "", CON {
            id = id,
            state = state,
            send_seqvar = send_seqvar,
            send_queue = send_queue,
            receive_seqvar = receive_seqvar,
            receive_queue = empty (),
            retran_queue = retran_queue,
            dup_count = dup_count,
            service_type = service_type
        }) 

    fun retran_dequeue (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) = 
        case dequeue retran_queue of 
            SOME (e, q) => 
                SOME (e, 
                    CON {
                        id = id,
                        state = state,
                        send_seqvar = send_seqvar,
                        send_queue = send_queue,
                        receive_seqvar = receive_seqvar,
                        receive_queue = receive_queue,
                        retran_queue = q,
                        dup_count = dup_count,
                        service_type = service_type
                    })
        |   NONE => NONE  

    fun retran_dropacked ack (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) =
        let fun drop q = 
                case dequeue q of 
                    SOME ({last_ack, payload = _}, new_q) => (
                        print ("last_ack: " ^ (Int.toString last_ack) ^ ", ack: " ^ (Int.toString ack) ^ "\n");
                        if last_ack <= ack then drop new_q
                        else q
                    )
                |   NONE => empty () 
        in 
            CON {
               id = id,
               state = state,
               send_seqvar = send_seqvar,
               send_queue = send_queue,
               receive_seqvar = receive_seqvar,
               receive_queue = receive_queue,
               retran_queue = drop retran_queue,
               dup_count = dup_count,
               service_type = service_type
            }
        end 

    fun getSSV (CON {id = _, state = _, send_seqvar, send_queue = _, receive_seqvar = _, receive_queue = _, retran_queue = _, dup_count = _ , service_type = _}) =
        let val SSV ssv = send_seqvar in ssv end

    fun getRSV (CON {id = _, state = _, send_seqvar = _, send_queue = _, receive_seqvar, receive_queue = _, retran_queue = _, dup_count = _, service_type = _}) =
        let val RSV rsv = receive_seqvar in rsv end

    type tcp_states = connection list

    fun empty_states () = [] 

    fun new_iss () = 0

    fun compareIDs (cid1 : connection_id, cid2 : connection_id) : bool =
        #source_addr cid1 = #source_addr cid2 andalso
        #source_port cid1 = #source_port cid2 andalso
        #dest_port cid1   = #dest_port cid2

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
                                          CLOSED      => "CLOSED"
                                        | LISTEN      => "LISTEN"
                                        | ESTABLISHED => "ESTABLISHED"
                                        | SYN_REC     => "SYN RECEIVED"
                                        | SYN_SENT    => "SYN SENT")
                val out = "From: " ^ sAdd ^ ":" ^ sPort ^ 
                    "\nTo: " ^ dPort ^
                    "\nState: " ^ stateStr ^ "\n\n"
            in 
                print out
            end)
        states
end

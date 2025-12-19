structure Connection = struct
    open Queue
    open SSV
    open RSV 

    type connection_id = {
        source_addr : int list,
        source_port : int,
        dest_port   : int
    }

    datatype tcp_state = ESTABLISHED | SYN_REC | CLOSE_WAIT | LAST_ACK

    datatype service_type = STREAM | FULL

    datatype connection = CON of {
        id             : connection_id,
        state          : tcp_state,
        send_seqvar    : send_seqvar,
        send_queue     : string queue,
        receive_seqvar : receive_seqvar,
        receive_queue  : string,
        retran_queue   : {last_ack : int, payload : string} queue,
        dup_count      : int,
        service_type   : service_type
    }

    fun update_state f (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) = (
        CON {
            id = id,
            state = f state,
            send_seqvar = send_seqvar,
            send_queue = send_queue,
            receive_seqvar = receive_seqvar,
            receive_queue = receive_queue,
            retran_queue = retran_queue,
            dup_count = dup_count,
            service_type = service_type
        }
    )

    fun update_sseqvar f (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) = (
        CON {
            id = id,
            state = state,
            send_seqvar = f send_seqvar,
            send_queue = send_queue,
            receive_seqvar = receive_seqvar,
            receive_queue = receive_queue,
            retran_queue = retran_queue,
            dup_count = dup_count,
            service_type = service_type
        }
    )

    fun update_rseqvar f (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type})  = (
        CON {
            id = id,
            state = state,
            send_seqvar = send_seqvar,
            send_queue = send_queue,
            receive_seqvar = f receive_seqvar,
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

    fun update_service_type f (CON {id, state, send_seqvar, send_queue, receive_seqvar, receive_queue, retran_queue, dup_count, service_type}) = (
        CON {
            id = id,
            state = state,
            send_seqvar = send_seqvar,
            send_queue = send_queue,
            receive_seqvar = receive_seqvar,
            receive_queue = receive_queue,
            retran_queue = retran_queue,
            dup_count = dup_count,
            service_type = f service_type
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
            val new_q = receive_queue ^ payload
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
        (receive_queue, CON {
            id = id,
            state = state,
            send_seqvar = send_seqvar,
            send_queue = send_queue,
            receive_seqvar = receive_seqvar,
            receive_queue = "",
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

end 
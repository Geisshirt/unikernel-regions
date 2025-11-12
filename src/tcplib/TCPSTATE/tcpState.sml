open Queue

structure TcpState : TCP_STATE = struct
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
        receive_seqvar : receive_seqvar,
        retran_queue   : {last_ack : int, payload : string} queue
    }

    fun retran_enqueue {last_ack, payload} (CON {id, state, send_seqvar, receive_seqvar, retran_queue}) =
        let
            val entry = {last_ack = last_ack, payload = payload}
            val new_q = enqueue (entry, retran_queue)
        in
            CON {
                id = id,
                state = state,
                send_seqvar = send_seqvar,
                receive_seqvar = receive_seqvar,
                retran_queue = new_q
            }  
        end

    fun retran_dequeue (CON {id, state, send_seqvar, receive_seqvar, retran_queue}) = 
        case dequeue retran_queue of 
            SOME (e, q) => 
                SOME (e, 
                    CON {
                        id = id,
                        state = state,
                        send_seqvar = send_seqvar,
                        receive_seqvar = receive_seqvar,
                        retran_queue = q
                    })
        |   NONE => NONE  

    fun retran_dropacked ack (CON {id, state, send_seqvar, receive_seqvar, retran_queue}) =
        let fun drop q = 
                case dequeue q of 
                    SOME ({last_ack, payload = _}, new_q) => 
                        if last_ack <= ack then drop new_q
                        else q
                |   NONE => empty () 
        in 
            CON {
               id = id,
               state = state,
               send_seqvar = send_seqvar,
               receive_seqvar = receive_seqvar,
               retran_queue = drop retran_queue
            }
        end 

    fun getSSV (CON {id = _, state = _, send_seqvar, receive_seqvar = _, retran_queue = _}) =
        let val SSV ssv = send_seqvar in ssv end

    fun getRSV (CON {id = _, state = _, send_seqvar = _, receive_seqvar, retran_queue = _}) =
        let val RSV rsv = receive_seqvar in rsv end

    type tcp_states = connection list

    fun empty_states () = [] 

    fun new_iss () = 42

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

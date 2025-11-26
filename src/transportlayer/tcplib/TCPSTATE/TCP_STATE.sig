signature TCP_STATE = sig
    datatype service_type = STREAM | FULL

    type tcp_states

    datatype tcp_state =  ESTABLISHED | SYN_REC | CLOSE_WAIT | LAST_ACK

    type connection_id = {
        source_addr : int list, 
        source_port : int, 
        dest_port   : int
    }

    datatype send_seqvar = SSV of {
        una : int,  (* Send unacknowledged *)
        nxt : int,  (* Send next *)
        wnd : int,  (* Send window *)
        up  : int,  (* Send urgent pointer *)
        wl1 : int,  (* Segment sequence number used for last window update *)
        wl2 : int,  (* Segment acknowledgement number used for last window update *)
        mss : int,
        iss : int   (* Initial sequence numbers *)
    }

    datatype receive_seqvar = RSV of {
        nxt : int, (* Receive next *)
        wnd : int, (* Receive window *)
        up  : int, (* Receive urgent pointer *)
        irs : int  (* Initial receive sequence number *)
    }

    datatype connection = CON of {
        id             : connection_id,
        state          : tcp_state,
        send_seqvar    : send_seqvar,
        send_queue     : string Queue.queue,
        receive_seqvar : receive_seqvar,
        receive_queue  : string Queue.queue,
        retran_queue   : {last_ack : int, payload : string} Queue.queue,
        dup_count      : int,
        service_type   : service_type
    }

    val effect : unit -> connection -> connection 

    val update_sseqvar : (send_seqvar -> send_seqvar) -> connection -> connection

    val update_rseqvar : (receive_seqvar -> receive_seqvar) -> connection -> connection

    val dup_inc : connection -> connection

    val dup_reset : connection -> connection

    val retran_enqueue : {last_ack : int, payload : string} -> connection -> connection

    val send_enqueue_many : string -> connection -> connection

    val send_dequeue : connection -> (string * connection) option

    val send_is_empty : connection -> bool

    val rec_enqueue : string -> connection -> connection

    val rec_collect : connection -> (string * connection)

    val retran_dequeue : connection -> ({last_ack : int, payload : string} * connection) option

    val retran_dropacked : int -> connection -> connection

    val getRSV: connection -> { nxt : int, wnd : int, up  : int, irs : int}

    val getSSV: 
        connection 
        -> 
        {
            una : int,
            nxt : int,
            wnd : int,
            up  : int,
            wl1 : int,
            wl2 : int,
            mss : int,
            iss : int 
        }

    val empty_states : unit -> tcp_states

    val new_iss : unit -> int

    val lookup : connection_id -> tcp_states -> connection option

    val add : connection -> tcp_states -> tcp_states

    val update : connection -> tcp_states -> tcp_states

    val update_state : (tcp_state -> tcp_state) -> connection -> connection

    val remove : connection_id -> tcp_states -> tcp_states

    val print_states : tcp_states -> unit
end
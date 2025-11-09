signature TCP_STATE = sig

    type tcp_states

    datatype tcp_state = CLOSED | LISTEN | ESTABLISHED | SYN_REC | SYN_SENT

    type connection_id = {
        source_addr: int list, 
        source_port: int, 
        dest_port: int
    }

    datatype connection = CON of {
        id               : connection_id,
        state            : tcp_state,
        sequence_number  : int,
        ack_number       : int
    }

    val empty_states : unit -> tcp_states

    val lookup : connection_id -> tcp_states -> connection option

    val add : connection -> tcp_states -> tcp_states

    val update : connection -> tcp_states -> tcp_states

    val print_states : tcp_states -> unit

    (* Remove?? *)
end
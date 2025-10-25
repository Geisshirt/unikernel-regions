signature TCP_STATE = sig
    datatype tcp_state = CLOSED | LISTEN | ESTABLISHED

    type connection_id = {
        source_addr: int list, 
        dest_addr: int list, 
        source_port: int, 
        dest_port: int
    }

    type connection = {
        id: connection_id,
        state: tcp_state,
        sequence_number: int,
        ack_number: int
    }

    val lookup : connection_id -> connection option

    val add : connection -> unit

    val update : connection -> unit

    (* Remove?? *)
end
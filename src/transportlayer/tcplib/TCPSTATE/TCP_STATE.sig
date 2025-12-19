(* 
    The TCP_STATE structure provides functionality for managing TCP 
    connections. This includes sequence and ack numbers as well as 
    send/recieve and retransmissions queues.
*)

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
        receive_queue  : string,
        retran_queue   : {last_ack : int, payload : string} Queue.queue,
        dup_count      : int,
        service_type   : service_type
    }

    val effect : unit -> connection -> connection 

    val update_sseqvar : (send_seqvar -> send_seqvar) -> connection -> connection

    val update_rseqvar : (receive_seqvar -> receive_seqvar) -> connection -> connection

    val update_service_type : (service_type -> service_type) -> connection -> connection

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

    val initCon : {
        connection_id : connection_id,
        receive_init : int,
        send_mss : int
    } -> connection

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

    val copy : tcp_states -> tcp_states

    val lookup : connection_id -> tcp_states -> connection option
    
    val add : connection -> tcp_states -> tcp_states

    val update : connection -> tcp_states -> tcp_states

    val update_state : (tcp_state -> tcp_state) -> connection -> connection

    val remove : connection_id -> tcp_states -> tcp_states

    val print_states : tcp_states -> unit
end

(* 
    [service_type] Full collects the entire message before giving it to 
    service and gives each segment as it receives it. 

    [tcp_states] The TCP state machine described in RFC 9293.

    [connection_id] Unique id for TCP states.

    [send_seqvar] Represents the send sequence fields in a TCP connection.

    [receive_seqvar] Represents the receive sequence fields in a TCP connection.

    [connection] Represents the fields needed for a connection including its 
    state.

    [effect] Performs a side effect on a connection for updating retransmissions.

    [update_sseqvar] Updates send sequence variables.

    [update_rseqvar] Updates receive sequence variables.

    [dup_inc] Increments the duplicate ack counter.

    [dup_reset] Sets the duplicate ack counter to zero. 

    [retran_enqueue] Enqueues a segment for retransmission.

    [send_enqueue_many] Enqueues multiple segments for retransmission.

    [send_dequeue] Dequeues a segment from the send queue, returns NONE if 
    empty.

    [send_is_empty] Returns true if send queue is empty false otherwise. 

    [rec_enqueue] Enqueues recieved payload into the receieve queue.

    [rec_collect] Collects and remove all data from the receice queue.

    [retran_dequeue] Dequeues the retransmission queue if any elements. 

    [retran_dropacked] Removes the acknowledged retransmission segments.

    [initCon] Initializes a new TCP connection with default sequence variables 
    and queues. State is SYN_REC.

    [getRSV] Returns receive sequence fields as a record. 
    
    [getSSV] Returns send sequence fields as a record. 

    [empty_states] Returns an empty tcp_states container.
    
    [new_iss] Returns an initial sequence number.
    
    [copy] Copies the tcp_states container.
    
    [lookup] Looks up a connection by connection_id.
    
    [add] Adds a new connection to the tcp_states container.
    
    [update] Updates a tcp_states connection.
    
    [update_state] Updates the tcp_states field of a connection using the 
    given function.
    
    [remove] Removes a connection from tcp_states by the connection_id
    
    [print_states] Pretty prints current tcp_states.
 *)

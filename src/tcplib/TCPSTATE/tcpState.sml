structure TcpState : TCP_STATE = struct
    datatype tcp_state = CLOSED | LISTEN | ESTABLISHED | SYN_REC | SYN_SENT | CLOSE_WAIT | LAST_ACK

    type connection_id = {
        source_addr : int list,
        source_port : int,
        dest_port   : int
    }

    datatype connection = CON of {
        id               : connection_id,
        state            : tcp_state,
        sequence_number  : int,
        ack_number       : int
    }

    type tcp_states = connection list

    fun empty_states () = [] 

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
                                    CLOSED => "CLOSED"
                                    | LISTEN => "LISTEN"
                                    | ESTABLISHED => "ESTABLISHED"
                                    | SYN_REC => "SYN RECEIVED"
                                    | SYN_SENT => "SYN SENT")
                val out = "From: " ^ sAdd ^ ":" ^ sPort ^ 
                    "\nTo: " ^ dPort ^
                    "\nState: " ^ stateStr ^ "\n\n"
            in 
                print out
            end)
        states
end

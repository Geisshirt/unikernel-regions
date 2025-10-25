structure TcpState : TCP_STATE = struct
    datatype tcp_state = CLOSED | LISTEN | ESTABLISHED

    type connection_id = {
        source_addr : int list,
        dest_addr   : int list,
        source_port : int,
        dest_port   : int
    }

    type connection = {
        id               : connection_id,
        state            : tcp_state,
        sequence_number  : int,
        ack_number       : int
    }

    val table : connection list ref = ref []

    fun compareIDs (cid1 : connection_id, cid2 : connection_id) : bool =
        #source_addr cid1 = #source_addr cid2 andalso
        #dest_addr cid1   = #dest_addr cid2   andalso
        #source_port cid1 = #source_port cid2 andalso
        #dest_port cid1   = #dest_port cid2

    fun lookup (cid : connection_id) : connection option =
        List.find (fn (c : connection) => compareIDs (#id c, cid)) (!table)

    fun add (conn : connection) : unit =
        table := conn :: !table

    (* Update removes the old entry and adds the new one. *)
    fun update (conn : connection) : unit =
        table :=
            conn :: List.filter
                (fn (c : connection) => not (compareIDs (#id c, #id conn)))
                (!table)
end

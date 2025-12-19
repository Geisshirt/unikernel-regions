open TcpState

val initCon : connection = CON {
    id = {source_addr = [0,0,0,0], source_port = 0, dest_port = 0},
    state = ESTABLISHED,
    send_seqvar = SSV {
        una = 0,
        nxt = 0,
        wnd = 0,
        up  = 0,
        wl1 = 0,
        wl2 = 0,
        mss = 5,
        iss = 0
    },
    send_queue = Queue.empty(),
    receive_seqvar = RSV {
        nxt = 0,
        wnd = 0,
        up  = 0,
        irs = 0 
    },
    receive_queue = "",
    retran_queue = Queue.empty(),
    dup_count = 0,
    service_type = FULL
}

val () = (
    setTestSuiteName "TCP";
    
    printStart ();

    assert ("send_enqueue_many",
            (fn () => let val CON con = (send_enqueue_many "abcd efgh ijkl " initCon) 
                      in #send_queue con |> Queue.toList
                      end),
            ["abcd ", "efgh ", "ijkl "],
            (fn l => "[" ^ (foldl (fn (s1, s2) => s1 ^ "," ^ s2)) "" l)
            );

    printResult ()
)

open Queue

val () = (
    setTestSuiteName "Queue";
    
    printStart ();

    assert("isEmpty on empty queue",
           (fn () => isEmpty (empty ())),
           true,
           Bool.toString);

    assert("isEmpty on non-empty queue",
           (fn () => isEmpty (enqueue (1, empty ()))),
           false,
           Bool.toString);

    assert("enqueue to empty",
           (fn () => enqueue (1, ([], []))),
           ([], [1]),
           (fn (f, b) => "(" ^ (Int.toString (List.length f)) ^ ", " ^ (Int.toString (List.length b)) ^ ")"));

    assert("enqueue to non-empty",
           (fn () => enqueue (1, ([], [1, 2]))),
           ([], [1, 1, 2]),
           (fn (f, b) => "(" ^ (Int.toString (List.length f)) ^ ", " ^ (Int.toString (List.length b)) ^ ")"));
    
    assert("dequeue non-empty",
           (fn () =>
                let
                    val q = enqueue (3, enqueue (2, enqueue (1, empty ())))
                in
                    case dequeue q of
                        SOME (x, _) => x
                      | NONE => 1
                end),
           1,
           Int.toString);

    assert("dequeue empty",
        (fn () => dequeue (empty ())),
        NONE,
        (fn opt => 
                case opt of
                    NONE   => "NONE"
                |   SOME _ => "SOME"));

    assert("peek empty",
        (fn () => peek (empty ())),
        NONE,
        (fn opt => 
                case opt of
                    NONE   => "NONE"
                |   SOME _ => "SOME"));

    assert("peek non-empty",
        (fn () => 
            let
                val q = enqueue (3, enqueue (2, enqueue (1, empty ())))
            in
                case peek q of
                    SOME x => x
                    | NONE => 1
            end),
        1,
        Int.toString);

    printResult ()
)
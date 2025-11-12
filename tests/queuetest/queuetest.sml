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
           (fn () => enqueue (1, empty ())),
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
                    |   NONE        => 1
                end),
           1,
           Int.toString);

    assert("dequeue empty",
        (fn () => empty () |> dequeue |> isSome),
        false,
        Bool.toString);

    assert("peek empty",
        (fn () => peek (empty ()) |> isSome),
        false,
        Bool.toString);

    assert("peek non-empty",
        (fn () => 
            let
                val q = enqueue (3, enqueue (2, enqueue (1, empty ())))
            in
                case peek q of
                    SOME (x, _) => x
                |   NONE        => 0
            end),
        1,
        Int.toString);

    printResult ()
)
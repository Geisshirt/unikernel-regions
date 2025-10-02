fun optionstr2str arg = 
    (case arg of 
        SOME (s, _) => "SOME " ^ s
    |   NONE => "NONE")

fun replicate n x =
    if n <= 0 then []
    else x :: replicate (n-1) x

fun permu_insert x [] = [[x]]
  | permu_insert x (y::ys) = (x::y::ys) :: (map (fn a => y::a) (permu_insert x ys)) 

fun flat l = foldl (op @) [] l

fun permutate [] = [[]]
  | permutate (x::xs) = flat (map (permu_insert x) (permutate xs))

functor MapTest (Map : MAP) :> MAPTEST = struct
    fun test () = 
        let val emptymap = Map.empty () 
        in (
            assert("Single fragment", fn () => (
                emptymap
                |> Map.add "0" (Map.Fragment {
                    offset = 0, 
                    length = 11, 
                    isLast = true, 
                    fragPayload = "hello world"})
                |> Map.assemble "0"
                |> optionstr2str
            ), "SOME hello world", fn x => x);

            assert("Two fragments in order", fn () => (
                emptymap
                |> Map.add "0" (Map.Fragment {
                    offset = 0, 
                    length = 2, 
                    isLast = false, 
                    fragPayload = "he"})
                |> Map.add "0" (Map.Fragment {
                    offset = 2, 
                    length = 3, 
                    isLast = true, 
                    fragPayload = "llo"})
                |> Map.assemble "0"
                |> optionstr2str
            ), "SOME hello", fn x => x);
        
            assert("Two fragments out of order", fn () => (
                emptymap
                |> Map.add "0" (Map.Fragment {
                    offset = 2, 
                    length = 3, 
                    isLast = true, 
                    fragPayload = "llo"})
                |> Map.add "0" (Map.Fragment {
                    offset = 0, 
                    length = 2, 
                    isLast = false, 
                    fragPayload = "he"})
                |> Map.assemble "0"
                |> optionstr2str
            ), "SOME hello", fn x => x);

            assert("Non-matching offsets", fn () => (
                emptymap
                |> Map.add "0" (Map.Fragment {
                    offset = 3, 
                    length = 3, 
                    isLast = true, 
                    fragPayload = "llo"})
                |> Map.add "0" (Map.Fragment {
                    offset = 0, 
                    length = 2, 
                    isLast = false, 
                    fragPayload = "he"})
                |> Map.assemble "0"
                |> optionstr2str
            ), "NONE", fn x => x);

            assert("First fragment lost", fn () => (
                emptymap
                |> Map.add "0" (Map.Fragment {
                    offset = 6, 
                    length = 6, 
                    isLast = false, 
                    fragPayload = "world "})
                |> Map.add "0" (Map.Fragment {
                    offset = 12, 
                    length = 5, 
                    isLast = false, 
                    fragPayload = "from "})
                |> Map.add "0" (Map.Fragment {
                    offset = 17, 
                    length = 5, 
                    isLast = true, 
                    fragPayload = "Mars!"})
                |> Map.add "0" (Map.Fragment {
                    offset = 0, 
                    length = 6, 
                    isLast = false, 
                    fragPayload = "Hello "})
                |> Map.assemble "0"
                |> optionstr2str
            ), "SOME Hello world from Mars!", fn x => x);

            assert("Remove assembled packets", fn () => (
                let val result = (
                        emptymap
                        |> Map.add "0" (Map.Fragment {
                            offset = 0, 
                            length = 11, 
                            isLast = true, 
                            fragPayload = "hello world"})
                        |> Map.assemble "0"
                    )
                in  case result of 
                        SOME (r, m) => r ^ ", " ^ (Map.assemble "0" m |> optionstr2str)
                    |   NONE => "NONE"
                end
                
            ), "hello world, NONE", fn x => x);

            assert("Assembling packets\n", fn () => (
                let val m = (
                        emptymap
                        |> Map.add "0" (Map.Fragment {
                            offset = 2, 
                            length = 4,
                            isLast = true, 
                            fragPayload = "llo "})
                        |> Map.add "0" (Map.Fragment {
                            offset = 0, 
                            length = 2, 
                            isLast = false, 
                            fragPayload = "He"})
                        |> Map.add "1" (Map.Fragment {
                            offset = 0, 
                            length = 3, 
                            isLast = false, 
                            fragPayload = "wor"})
                        |> Map.add "1" (Map.Fragment {
                            offset = 3, 
                            length = 3, 
                            isLast = true, 
                            fragPayload = "ld "})
                        |> Map.add "2" (Map.Fragment {
                            offset = 0, 
                            length = 5, 
                            isLast = false, 
                            fragPayload = "from "})
                        |> Map.add "2" (Map.Fragment {
                            offset = 9, 
                            length = 1, 
                            isLast = true, 
                            fragPayload = "!"})
                        |> Map.add "2" (Map.Fragment {
                            offset = 5, 
                            length = 4, 
                            isLast = false, 
                            fragPayload = "Mars"})
                    )
                in  (optionstr2str o Map.assemble "0") m ^ 
                    (optionstr2str o Map.assemble "1") m ^  
                    (optionstr2str o Map.assemble "2") m 
                end
                
            ), "SOME Hello SOME world SOME from Mars!", fn x => x);

            assert("Assembling packets\n", fn () => (
                map (fn frags => foldl (fn (m, f) => Map.add "0" m f) emptymap frags |> Map.assemble "0" |>  optionstr2str) 
                (permutate [
                    Map.Fragment {
                        offset = 0, 
                        length = 2, 
                        isLast = false, 
                        fragPayload = "He"
                    },
                    Map.Fragment {
                        offset = 2, 
                        length = 4, 
                        isLast = false, 
                        fragPayload = "llo "
                    },
                    Map.Fragment {
                        offset = 6, 
                        length = 6, 
                        isLast = false, 
                        fragPayload = "world "
                    },
                    Map.Fragment {
                        offset = 12, 
                        length = 5, 
                        isLast = true, 
                        fragPayload = "from "
                    }
                ]) |> foldl (fn (s, fs) => s ^ "\n" ^ fs) ""
            ), replicate 24 "SOME Hello world from " |> foldl (fn (s, fs) => s ^ "\n" ^ fs) "", 
            fn x => x);

            assert("Assembling packets\n", fn () => (
                    emptymap
                    |> Map.add "0" (Map.Fragment {
                        offset = 0, 
                        length = 2, 
                        isLast = false, 
                        fragPayload = "He"
                    })
                    |> Map.add "0" (Map.Fragment {
                        offset = 2, 
                        length = 4, 
                        isLast = false, 
                        fragPayload = "llo "
                    })
                    |> Map.add "0" (Map.Fragment {
                        offset = 12, 
                        length = 5, 
                        isLast = true, 
                        fragPayload = "from "
                    })
                    |> Map.add "0" (Map.Fragment {
                        offset = 6, 
                        length = 6, 
                        isLast = false, 
                        fragPayload = "world "
                    })

                    |> Map.assemble "0"
                    |> optionstr2str
            ), "SOME Hello world from ", fn x => x)
        )
        end
end

                    (* 
                    Map.Fragment {
                        offset = 17, 
                        length = 4, 
                        isLast = false, 
                        fragPayload = "Mars"
                    },
                    Map.Fragment {
                        offset = 21, 
                        length = 1, 
                        isLast = true, 
                        fragPayload = "!"
                    } *)

structure testMapL = MapTest(MapL)

val () = (
    setTestSuiteName "Map - MapL";
    
    printStart ();

    testMapL.test ();

    printResult ()
)

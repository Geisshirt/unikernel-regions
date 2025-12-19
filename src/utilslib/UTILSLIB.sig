(*
    The Utils structure provides useful infix extenstions to SML as well as 
    useful helper functions. 
*)

signature UTILSLIB = 
    sig
        val findi  : ('a -> bool) -> 'a list -> (int * 'a) option
        val copyList : string list -> string list
    end

(*
    [findi] finds the the element that matches the predicate function.

    [copyList] copies a list (useful in the 'double copy' trick).
*)
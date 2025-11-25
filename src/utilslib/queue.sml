signature QUEUE = sig
    type 'a queue
    val empty    : unit -> 'a queue
    val fromList : 'a list -> 'a queue
    val toList   : 'a queue -> 'a list
    val length   : 'a queue -> int
    val isEmpty  : 'a queue -> bool
    val enqueue  : 'a * 'a queue -> 'a queue
    val dequeue  : 'a queue -> ('a * 'a queue) option
    val peek     : 'a queue -> ('a * 'a queue) option
end

structure Queue :> QUEUE = struct
    type 'a queue = 'a list * 'a list

    fun empty () : 'a queue = ([], [])

    fun fromList list = (list, [])

    fun toList ((front, back) : 'a queue) = front @ List.rev back

    fun length ((f, b): 'a queue) : int =
        List.length f + List.length b

    fun isEmpty (q : 'a queue) : bool  =
        case q of
            ([], []) => true
        |   _        => false

    fun enqueue (x : 'a, (f, b) : 'a queue) : 'a queue = 
        (f, x :: b)

    fun dequeue ((f, b) : 'a queue) : ('a * 'a queue) option = 
        case f of
            x :: xs => SOME (x, (xs, b))
        |   []      => case List.rev b of
                           []      => NONE
                       |   y :: ys => SOME (y, (ys, []))

    fun peek ((f, b) : 'a queue) : ('a * 'a queue) option =
        case f of
            x :: _ => SOME (x, (f, b))
        |   []     => (case List.rev b of
                           []     => NONE
                      |    y :: ys => SOME (y, (y :: ys, [])))

end

(* 
    Queue implemented with two lists, (front * back), to achieve constant amortized enqueue and dequeue.

    front: holds the elements the dequeue order i.e. oldest first.
    back: holds the elements the queued order i.e. newest first.
*)


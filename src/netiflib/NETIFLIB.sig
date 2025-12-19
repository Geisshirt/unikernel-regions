(*
    The netiflib structure provides useful functions for a reading and writing to a 'tap'.
*)

signature NETIF = sig 
    val init : unit -> unit
    val receive : unit -> string 
    val send : int list -> unit
end 

(*
    [receive] Reads from the 'tap' and returns what was read as a string.

    [send] Writes a bytelist to a 'tap'.
*)
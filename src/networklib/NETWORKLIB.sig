(* 
    The networlib structure provides functions to bind a callback function to a internet port and a 
    function to start the infinite listen. 
*)

signature NETWORK = sig
    type port = int
    type callback = string -> string
    val logOn : unit -> unit
    val logOff : unit -> unit  
    val listen : Service.service -> unit
end

(*
[logOn] turns on logging

[logOff] turns off logging.

[bindUDP] binds a port number to a callback function.

[listen] keeps the application listening for any and all network messages. It will only handle the 
ones that has been bound.  
*)
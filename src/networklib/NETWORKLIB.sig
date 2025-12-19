(* 
    The networlib structure provides functions to bind a callback function to a internet port and a 
    function to start the infinite listen. 
*)

signature NETWORK = sig
    type port = int
    
    type callback = string -> string
    
    val listen : unit -> unit
end

(*
    [listen] keeps the application listening for any and all network messages. It will only handle the 
    ones that has been bound.  
*)
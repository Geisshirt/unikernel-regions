structure NetworkDefault = Network(IPv4L)

open NetworkDefault
open Protocols (* Include in default? *)

(* Next steps:
- Do some operation on the list - it is reversed for display
- Clear history older than n entries or max n entries - set to 2 for testing
- use explicit regions
- use forceReset region, to clear history, by copying to a new region and back
- make a way to exit the server gracefully

- Follow `data` through regions
- Think about and look at how to specify services
  - Specifically how/where `data` is stored, and how we can
    clear it safely
  - Copy data to fresh region, when arrived, and give to service 
   remove from packet list
- Write about new knowledge
*)

(* Take up to n elements from the list l *)
(* Returns the whole list if n > length l *)
(* \/ a,r. (list`r a, int) -> list`r a *)
fun takeSafe (l, n) =
	let
	  val len = List.length l
	in
	  if n < len then
		List.take (l, n)
	  else
	  	l
		(* List.take (l, len) *)
	end

(* Copy a list of strings to a new region *)
(* \/ r,r'. list`r string -> list`r' string *)
fun copyList [] = []
  | copyList (x::xr) = (x ^ "") :: copyList xr

fun handler data sList =
	if data = "exit" then (
	  print "Exiting server...\n";
	  "Server cannot be stopped gracefully yet\n"
	) else (
	  print ("Added: " ^ data ^ "\n");
	  sList := (data ^ "\n") :: !sList;
	  sList := takeSafe (!sList, 2);
	  let 
		val revList = List.rev (!sList)
	  in
		print ("Current list:\n" ^ String.concatWith "> " (revList));
		String.concatWith "> " (revList)
	  end
	)

(* \/ r,r'.(string,r) -> (string,r') *)
fun service `[r1 r2 r3] ()  =
    let
	  val sList = ref`r1 ([] : string`r2 list`r3)
	in
      fn data =>
		let
		  val temp = copyList (!sList)
		  val a = !sList
		in
		  forceResetting (a);
		  sList := copyList temp;
		  handler data sList
		end
	end

fun run () = (
  print "Starting UDP server on port 8080...\n";
  let with r1 r2 r3
  in
  listen [
	(UDP, [(8080, service `[r1 r2 r3] ())])
  ]
  end
)

val _ = run () 

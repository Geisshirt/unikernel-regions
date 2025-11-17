(* A mock server implementation *)
(* Using regions to make sure we can reset state between requests *)
(* and that we can reset request data after each request *)

(* Define the type of subservice *)
datatype subservice =
    Exit
  | Nothing
  | Chat
  | History

type instream = {ic: int, name: string}

exception CannotOpen

fun getCtx () : foreignptr = prim("__get_ctx",())

fun chr_unsafe (i:int):char = prim ("id", i)

fun input1_ (ic:int) : int = prim ("input1Stream", ic)

fun input1 ({ic, name} : instream) : char option =
	let val res = input1_ ic
	in if res < 0 then NONE
	   else SOME (chr_unsafe res)
	end

fun openIn (f: string) : instream =
	{ic=prim("openInStream",(getCtx(), f, CannotOpen)),
	 name=f} handle exn => raise Fail "openIn"

fun closeIn ({ic,...} : instream) : unit = prim ("closeStream", ic)

fun inputLine is =
	let fun loop(acc) =
		case input1 is
		  of SOME (c as #"\n") => SOME(implode(rev(c :: acc)))
		| SOME c => loop(c::acc)
		| NONE => case acc
					of [] => NONE
				  | _ => SOME(implode(rev(#"\n" :: acc)))
	in loop([])
	end

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
	end

(* Copy a list of strings to a new region *)
(* \/ r,r'. list`r string -> list`r' string *)
fun copyList [] = []
  | copyList (x::xr) = (x ^ "") :: copyList xr

(* Copy a string to a new region *)
(* \/ r,r'. string`r -> string`r' *)
fun copyString `[r1 r2] (s : string`r1) : string`r2 = s ^ ""

(* Mock request function *)
(* Reads data from a file, which contains all simulated network data *)
(* Splits the data into service type and actual data, delimiter is `:` *)
(* \/ r.  -> string`r *)
fun req `r (inStream : instream) : subservice * string`r =
	let with r1
	  val line : string`r1 option = inputLine inStream 
	in
	  case line of
		SOME l => (
		  	case String.fields (fn c => c = #":") l of
			  ("exit"::rest) => (Exit, "")
			| ("chat"::rest) => (Chat, String.concatWith ":" rest)
			| ("history"::rest) => (History, "")
			| _ => (Nothing, "")
		)
	  | NONE =>
		    (Exit, "")
	end

(* Mock response function *)
(* Sends data to the client by printing it to the console *)
(* \/ r. string`r ->  unit *)
fun resp `r (data: string`r) : unit =
	print ("Response sent to client: " ^ data)

(* chat subservice *)
(* appends data to state and returns a response *)
(* \/ r,r',r'',r'''. (string`r' list`r, string`r'') -> (string`r''', string`r' list`r) *)
fun chat `[r1 r2 r3 r4] (state : string`r1 list`r2) (data: string`r3) : string`r4 * string`r1 list`r2 =
	let with r5 r6
	  val temp : string`r5 list`r6 = data ^ "" :: copyList state
	  val _ = forceResetting (state)
	  val response : string`r4 = "Chat received: " ^ data
	  val newState : string`r1 list`r2 = copyList (takeSafe (temp, 100))
	in
	  (response, newState)
	end

(* history subservice *)
(* returns the last 2 chat messages from state *)
(* \/ r,r',r'',r'''. (string`r' list`r) -> string`r''' *)
fun history `[r1 r2 r4] (state: string`r1 list`r2) : string`r4 =
	let
	  val recentHistory = takeSafe (state, 2)
	  val revList = List.rev recentHistory
	  val response : string`r4 = String.concatWith "> " (revList)
	in
	  response
	end

(* service function *)
(* responsible for handling requests and running corresponding subroutines *)
(* Carries state between requests and operates in a loop *)
(* \/ r,r'.(string,r) -> (string,r') *)
fun service `[r1 r2] (inStream : instream) (state : string`r1 list`r2) : unit =
	let
	  val state' =
		let with r3 r4
		  val (subservice, data : string`r3) = req (inStream) : subservice * string`r3
		in
		  case subservice of
			Exit => (
			  print "Exiting service loop...\n";
			  raise Fail "Service exited"
			)
		  | Nothing => (
			  print "No valid subservice requested. Continuing...\n";
			  state
			)
		  | Chat => (
			  let
				val (response : string`r4, state') = chat `[r1 r2 r3 r4] state data
			  in
				resp (response : string`r4);
				state'
			  end
			)
		  | History => (
			  let
				val response : string`r4 = history `[r1 r2 r4] state
			  in
				resp (response : string`r4);
				state
			  end
			)
		end
	in
	  service `[r1 r2] inStream state'
	end

fun run () = (
  print "Starting mock server\n";
  let with r1 r2
	val inStream : instream = openIn "mock_requests.txt"
    val state = [] : string`r1 list`r2
  in
	service `[r1 r2] inStream state handle Fail msg => (
		closeIn inStream;
		print ("Service loop exited with: " ^ msg ^"\n")
	  )
  end
)

val _ = run () 

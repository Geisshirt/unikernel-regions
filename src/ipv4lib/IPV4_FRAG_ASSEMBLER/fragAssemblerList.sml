structure FragAssemblerList :> FRAG_ASSEMBLER = 
struct
  type id = string
  type payload = string

  datatype fragment = Fragment of {
    offset : int,
    length : int,
    isLast : bool,
    fragPayload : payload
  }

  type nxtOffset = int
  
  type fragContainer = (id * nxtOffset * (fragment list)) list

  (* fun lookup id m : fragment list option = 
    case List.find (fn (k, _, _) => k = id) m of
          SOME (_, _, l) => SOME l
        | NONE => NONE *)

  (* What happens with double replacement ? *)
  fun copyFragList `[r1 r2 r3 t1 t2 t3] (l : fragment`[r2 r3] list`[r1]) : fragment`[t2 t3] list`[t1] = 
    case l of 
      [] => []
    | (Fragment {offset, length, isLast, fragPayload}) :: xs => 
      ((Fragment {
        offset = offset,
        length = length,
        isLast = isLast,
        fragPayload = fragPayload ^ ""
      }) :: copyFragList xs)
(* fn (id, nxtOff, fl) => (id, nxtOff, copyList (
      fn () => 
    ) fl)) fc  *)
  (* What happens with double replacement ? *)
  fun copy `[r1 r2 r3 r4 r5 t1 t2 t3 t4 t5] (fc : (id * nxtOffset * (fragment`[r4 r5] list`r3))`r2 list`r1) : (id * nxtOffset * (fragment`[t4 t5] list`t3))`t2 list`t1  =
    let fun copyListFs [] = []
          | copyListFs ((id, nxtOff, fl) :: xs) = (id, nxtOff, copyFragList fl) :: copyListFs xs
    in 
      copyListFs fc
    end

  fun add id (Fragment frag) (m : fragContainer) : fragContainer = 
    let val offset = (#offset frag)
        val length = (#length frag)
        fun replace [] = (id, if offset = 0 then length else 0, [Fragment frag]) :: m
          | replace ((k, nxtoff, l) :: ms) = 
              if k <> id then (k, nxtoff, l)::replace ms
              else
                let fun updatePrevFrags new_nxtoff [] nxtFrags = (new_nxtoff, nxtFrags)
                      | updatePrevFrags new_nxtoff (Fragment frag2 :: pfs) nxtFrags =
                          if (#offset frag2) = new_nxtoff 
                             then updatePrevFrags ((#offset frag2) + (#length frag2)) pfs (Fragment frag2 :: nxtFrags)
                             else updatePrevFrags new_nxtoff pfs (Fragment frag2 :: nxtFrags)
                    fun insertFrag prevFrags nxtFrags =
                          case nxtFrags of 
                            []  => updatePrevFrags (if offset = 0 then length else nxtoff) prevFrags [Fragment frag]
                          | (Fragment frag2 :: nfs) => 
                              (if offset >= (#offset frag2) + (#length frag2)
                              then (
                                  updatePrevFrags 
                                    (if offset = nxtoff then offset+length else nxtoff) 
                                    prevFrags
                                    (Fragment frag :: nxtFrags))
                              else (insertFrag (Fragment frag2 :: prevFrags) nfs))
                    val (new_nxtoff, new_l) = insertFrag [] l
                in  (k, new_nxtoff, new_l) :: ms
                end 
    in  replace m 
    end

  fun assemble id m : (string * fragContainer) option = 
    let val assembledPayload : (string option) ref = ref NONE
        fun removeAndAssemble [] = []
          | removeAndAssemble ((_, _, []) :: ms) = ms
          | removeAndAssemble ((k, nxtOff, (Fragment fh)::ft) :: ms) =
              if k = id then
                ( if (#isLast fh) andalso nxtOff = (#offset fh + #length fh) then (
                  assembledPayload := SOME (foldl (fn ((Fragment f), fs) => (#fragPayload f) ^ fs) "" ((Fragment fh)::ft));
                  ms)
                else [])
              else (k, nxtOff, (Fragment fh)::ft) :: removeAndAssemble ms
        val newList = removeAndAssemble m
    in  case !assembledPayload of 
          SOME s => SOME (s, newList)
        | NONE => NONE
    end

  fun empty () : fragContainer = []
end
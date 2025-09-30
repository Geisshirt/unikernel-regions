structure MapL : MAP = struct
  type nxtOffset = int
  type offset = int
  type length = int
  type id = string
  type 'a frags = (offset * length * 'a) list
  type 'a t = (id * nxtOffset * 'a frags) list

  fun lookup m id : 'a frags option = 
    case List.find (fn (k, _, _) => k = id) m of
          SOME (_, _, l) => SOME l
        | NONE => NONE

  fun add (m : 'a t) id (offset, length, fragment) : 'a t = 
    let fun coolReplace [] = 
              (* Empty map. *)
              (id, if offset = 0 then length else 0, [(offset, length, fragment)]) :: m
          | coolReplace ((k, nxtoff, l) :: ms) = 
              if k = id then 
                let fun updatePrevFrags new_nxtoff [] nxtFrags = (new_nxtoff, nxtFrags)
                      | updatePrevFrags new_nxtoff ((offset2, length2, fragment2) :: pfs) nxtFrags = 
                          if offset2 = new_nxtoff 
                          then updatePrevFrags (offset2 + length2) pfs ((offset2, length2, fragment2) :: nxtFrags)
                          else (new_nxtoff, pfs @ ((offset2, length2, fragment2) :: nxtFrags))
                    fun insertFrag prevFrags nxtFrags =
                          case nxtFrags of 
                            [] => updatePrevFrags nxtoff prevFrags [(offset, length, fragment)]
                          | ((offset2, length2, fragment2) :: nfs) =>
                              if offset = offset2 + length2 
                              then 
                                updatePrevFrags 
                                  (if offset = nxtoff then offset+length else nxtoff) 
                                  prevFrags
                                  ((offset, length, fragment) :: nxtFrags)
                              else insertFrag ((offset2, length2, fragment2) :: prevFrags) nfs
                    val (new_nxtoff, new_l) = insertFrag [] l
                in (k, new_nxtoff, new_l) :: ms
                end 
              else 
                (k, nxtoff, l)::coolReplace ms
    in 
        coolReplace m 
    end

  fun empty () : 'a t = []
end
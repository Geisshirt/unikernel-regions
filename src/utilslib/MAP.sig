signature MAP = sig 
  type 'a t
  type offset
  type length
  type id
  type 'a frags

  val lookup : 'a t -> id -> 'a frags option

  val add : 'a t -> id -> (offset * length * 'a) -> 'a t

  val empty : unit -> 'a t
end 

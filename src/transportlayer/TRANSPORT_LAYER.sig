signature TRANSPORT_LAYER = sig

  type context

  type protocol = int

  val protToString : protocol -> string

  datatype info = INFO of {
    ownMac     : int list,
    dstMac     : int list,
    ownIPaddr  : int list,
    dstIPaddr  : int list,
    ipv4Header : IPv4Codec.header,
    payload : string
  }

  val copyContext : context`r -> context`r'

  val initContext : unit -> context`r

  val resetContext : context -> unit

  val handl : protocol -> info -> context -> context

end
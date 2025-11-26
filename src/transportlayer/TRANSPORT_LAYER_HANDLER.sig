signature TRANSPORT_LAYER_HANDLER = sig
  type h_context

  type info = {
    service    : Service.service,
    ownMac     : int list,
    dstMac     : int list,
    ownIPaddr  : int list,
    dstIPaddr  : int list,
    ipv4Header : IPv4Codec.header,
    payload : string
  }

  val initContext : unit -> h_context

  val protocol_int : int

  val protocol_string : string

  val handl : info -> h_context -> h_context
end 
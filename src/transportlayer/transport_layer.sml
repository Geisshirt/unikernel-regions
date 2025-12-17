functor TransportLayerSingle(tlh : TRANSPORT_LAYER_HANDLER) :> TRANSPORT_LAYER = struct 

  type context = tlh.h_context

  type protocol = int

  datatype info = INFO of {
    ownMac     : int list,
    dstMac     : int list,
    ownIPaddr  : int list,
    dstIPaddr  : int list,
    ipv4Header : IPv4Codec.header,
    payload : string
  }

  fun copyContext `[r1 r2] (c: context`r1) : context`r2 = tlh.copyContext c

  fun initContext `r () : context`r = tlh.initContext ()

  fun resetContext (c : context) = resetRegions c

  fun protToString prot = if prot = tlh.protocol_int then tlh.protocol_string else "Unknown"

  fun handl (prot : protocol) (INFO ipv4_info : info) (con : context) = 
    if prot = tlh.protocol_int then tlh.handl ipv4_info con else con

end

functor TransportLayerComb(structure tl : TRANSPORT_LAYER 
                           structure tlh : TRANSPORT_LAYER_HANDLER) :> TRANSPORT_LAYER = struct 

  type context = tlh.h_context * tl.context

  type protocol = int

  datatype info = INFO of {
    ownMac     : int list,
    dstMac     : int list,
    ownIPaddr  : int list,
    dstIPaddr  : int list,
    ipv4Header : IPv4Codec.header,
    payload : string
  }

  fun copyContext (c : context) : context = (tlh.copyContext (#1 c), tl.copyContext (#2 c))

  fun initContext `r () : context`r = (tlh.initContext (), tl.initContext ())

  fun resetContext ((hc, c) : context) = (
    resetRegions hc;
    tl.resetContext c
  )

  fun protToString prot = if prot = tlh.protocol_int then tlh.protocol_string else tl.protToString prot

  fun handl (prot : protocol) (INFO ipv4_info : info) (con : context) = 
    if prot = tlh.protocol_int then (tlh.handl ipv4_info (#1 con), #2 con) else (#1 con, tl.handl prot (tl.INFO ipv4_info) (#2 con))

end 

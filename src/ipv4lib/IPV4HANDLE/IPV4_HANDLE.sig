signature IPV4_HANDLE = sig
    type context

    type port = int

    type bindingList = (port * (string -> string)) list

    datatype pbindings = PBindings of {
      UDP : bindingList, 
      TCP : bindingList
    }

    val initContext : unit -> context

    val handl   : {protBindings : pbindings, 
                   ownIPaddr : int list,
                   ownMac : int list, 
                   dstMac : int list, 
                   ipv4Packet : string} -> context -> context

end
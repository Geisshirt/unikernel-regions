signature IPV4_HANDLE = sig
    type fragContainer

    type port = int

    type bindingList = (port * (string -> string)) list

    datatype pbindings = PBindings of {
      UDP : bindingList, 
      TCP : bindingList
    }

    val emptyFragContainer : unit -> fragContainer

    val handl   : {fragContainer : fragContainer,
                   protBindings : pbindings, 
                   ownIPaddr : int list,
                   ownMac : int list, 
                   dstMac : int list, 
                   ipv4Packet : string} -> fragContainer

end
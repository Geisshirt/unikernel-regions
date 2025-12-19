(* 
    The TCP_HANDLE structure provides functionality for handling any incoming
    TCP requests propagating them to the appropiate service.
*)

signature TCP_HANDLE = sig
    datatype info = INFO of {
        ownMac     : int list,
        dstMac     : int list,
        ownIPaddr  : int list,
        dstIPaddr  : int list,
        ipv4Header : IPv4Codec.header,
        payload : string
    }

    val initContext : unit -> context

    val handl : info -> TcpState.tcp_states -> TcpState.tcp_states
end

(* 
    [info] Contains information passed from the IPv4 layer.

    [initContext] Initializes and returns a fresh TCP state container.

    [handl] Handles incoming TCP packets by updating the TCP_states container.
 *)
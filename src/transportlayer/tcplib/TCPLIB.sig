(* 
    The TCP structure provides handling of TCP packets while maintaining 
    TCP state across multiple connections.
*)

signature TCP = sig
    type context = TcpState.tcp_states

    val handl : {
        service: Service.service,
        ownMac : int list,
        dstMac : int list,
        ownIPaddr : int list,
        dstIPaddr : int list,
        ipv4Header : IPv4Codec.header,
        tcpPayload : string
    } -> context -> context

    val initContext : unit -> context
end

(* 
    [handl] Handles an incoming TCP packet which is propagated to appropiate 
    service.

    [initContext] Initializes and returns a fresh TCP context.
 *)

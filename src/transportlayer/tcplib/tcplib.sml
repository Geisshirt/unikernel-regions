structure Tcp :> TCP = struct
    type context = TcpState.tcp_states

    type port = int

    fun handl args context = TcpHandle.handl args context

    fun initContext () = TcpState.empty_states()
end
structure Tcp :> TCP = struct

    type port = int

    fun handl args = TcpHandle.handl args

end
structure Service = struct
  type port = int

  datatype ServiceProtocol = TCPService | UDPService

  datatype ServiceReply = SETUP_STREAM | SETUP_FULL | REPLY of string | IGNORE

  datatype HandlerRequest = SETUP | REQUEST of string

  type service = (port * ServiceProtocol * HandlerRequest) -> ServiceReply
end
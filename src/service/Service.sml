structure Service = struct
  type port = int

  datatype ServiceReply = SETUP_STREAM | SETUP_FULL | REPLY of string | IGNORE

  datatype HandlerRequest = SETUP | REQUEST of string

  type service = (port * HandlerRequest) -> ServiceReply
end
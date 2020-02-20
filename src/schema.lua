local typedefs = require "kong.db.schema.typedefs"

return {
  name = "obfuscated-udp-log",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { host = typedefs.host({ required = true }) },
          { port = typedefs.port({ required = true }) },
          { timeout = { type = "number", default = 10000 }, },
          { obfuscate_request_body = { type = "boolean", required = true, default = true }, },
          { obfuscate_response_body = { type = "boolean", required = true, default = true }, },
          { keys_to_obfuscate = { type = "set", elements = { type = "string"} } },
          { mask = { type = "string", required = true, default = "***" } },
          { original_body_on_error = { type = "boolean", required = true, default = false }, },
    }, }, },
  },
}

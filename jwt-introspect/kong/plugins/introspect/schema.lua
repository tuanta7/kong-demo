local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "introspect"

return {
    name = PLUGIN_NAME,
    fields = {{
        config = {
            type = "record",
            fields = {{
                key = {
                    type = "string",
                    description = "Verification key",
                    required = true
                }
            }, {
                redis_host = typedefs.hosts({
                    required = true
                })
            }, {
                redis_port = typedefs.port({
                    required = true
                })
            }}
        }
    }}
}


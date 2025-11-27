local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "jwt-introspect"

return {
    name = PLUGIN_NAME,
    fields = {{
        config = {
            type = "record",
            fields = {{
                key = {
                    type = "string",
                    description = "Verification key"
                }
            }}
        }
    }}
}

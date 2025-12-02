local typedefs = require "kong.db.schema.typedefs"

return {
    name = "introspect",
    fields = {{
        config = {
            type = "record",
            fields = {{
                jwks_uri = {
                    type = "string",
                    description = "JWKS endpoint URI to fetch public keys",
                    required = true
                }
            }, {
                issuer = {
                    type = "string",
                    description = "Expected token issuer (iss claim)",
                    required = false
                }
            }, {
                audience = {
                    type = "string",
                    description = "Expected token audience (aud claim)",
                    required = false
                }
            }, {
                require_exp = {
                    type = "boolean",
                    description = "Require expiration claim in token",
                    default = true
                }
            }, {
                clock_skew = {
                    type = "integer",
                    description = "Allowed clock skew in seconds",
                    default = 60
                }
            }, {
                cache_ttl = {
                    type = "integer",
                    description = "JWKS cache TTL in seconds",
                    default = 36000 -- 10hrs
                }
            }, {
                redis_host = typedefs.host({
                    required = true
                })
            }, {
                redis_port = typedefs.port({
                    required = true,
                    default = 6379
                })
            }, {
                redis_password = {
                    type = "string",
                    description = "Redis password (optional)",
                    required = false
                }
            }, {
                redis_db = {
                    type = "integer",
                    description = "Redis database number",
                    default = 0,
                    required = false
                }
            }}
        }
    }}
}


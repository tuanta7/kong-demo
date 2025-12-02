local key = require("kong.plugins.introspect.key")
local token = require("kong.plugins.introspect.token")

local plugin = {
    PRIORITY = 1000,
    VERSION = "0.1.0-0"
}

function plugin:init_worker()
    kong.log.debug("JWT introspection plugin initialized")
end

function plugin:access(conf)
    local auth_header = kong.request.get_header("Authorization")
    local jwt, extract_err = token.extract_token(auth_header)
    if not jwt then
        kong.log.warn("Token extraction failed: ", extract_err)
        return kong.response.exit(401, {
            message = "Unauthorized",
            error = extract_err
        })
    end

    local options = {
        issuer = conf.issuer,
        audience = conf.audience,
        require_exp = conf.require_exp,
        clock_skew = conf.clock_skew
    }

    local payload, err = token.validate_token(conf, jwt, conf.jwks_uri, options)
    if not payload then
        kong.log.warn("Token validation failed: ", err)
        return kong.response.exit(401, {
            message = "Unauthorized",
            error = err
        })
    end

    local is_blacklisted, blacklist_err = key.is_blacklisted(conf, payload.jti)
    if blacklist_err then
        kong.log.err("Blacklist check failed: ", blacklist_err)
        return kong.response.exit(500, {
            message = "Internal Server Error",
            error = "Failed to verify token status"
        })
    end

    if is_blacklisted then
        kong.log.warn("Token is blacklisted, jti: ", payload.jti)
        return kong.response.exit(401, {
            message = "Unauthorized",
            error = "Token has been revoked"
        })
    end

    kong.log.info("Token validated successfully for subject: ", payload.sub or "unknown")

    if payload.sub then
        kong.service.request.set_header("X-Auth-Subject", payload.sub)
    end

    -- Store the full payload in Kong's context for other plugins
    -- kong.ctx.shared.jwt_payload = payload
end

return plugin

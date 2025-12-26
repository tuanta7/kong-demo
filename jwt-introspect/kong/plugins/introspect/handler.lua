local token = require("kong.plugins.introspect.token")
local exporter = require('kong.plugins.prometheus.exporter')

local prometheus
local metrics = {}

local plugin = {
    PRIORITY = 1000,
    VERSION = "0.1.0-0"
}

function plugin:init_worker()
    prometheus = exporter.get_prometheus()
    if not prometheus then
        kong.log.err("Failed to get Prometheus exporter")
        return
    end
    kong.log.info("Prometheus exporter initialized")

    -- Request counting metrics
    metrics.total_requests = prometheus:counter("introspect_requests_total",
        "Total requests to JWT introspection plugin")

    metrics.successful_validations = prometheus:counter("introspect_successful_validations_total",
        "Total successful token validations")

    metrics.failed_extractions = prometheus:counter("introspect_failed_extractions_total",
        "Total failed token extractions")

    metrics.failed_validations = prometheus:counter("introspect_failed_validations_total",
        "Total failed token validations")

    metrics.blacklisted_tokens = prometheus:counter("introspect_blacklisted_tokens_total",
        "Total blacklisted token attempts")

    metrics.blacklist_errors = prometheus:counter("introspect_blacklist_errors_total", "Total blacklist check errors")

    kong.log.debug("JWT introspection plugin initialized")
end

function plugin:access(conf)
    -- Count total requests
    metrics.total_requests:inc(1)

    local auth_header = kong.request.get_header("Authorization")
    local jwt, extract_err = token.extract_token(auth_header)
    if not jwt then
        kong.log.warn("Token extraction failed: ", extract_err)
        metrics.failed_extractions:inc(1)
        return kong.response.exit(401, {
            message = "Unauthorized",
            error = extract_err
        })
    end

    local payload, err = token.validate_token(conf, jwt)
    if not payload then
        kong.log.warn("Token validation failed: ", err)
        metrics.failed_validations:inc(1)
        return kong.response.exit(401, {
            message = "Unauthorized",
            error = err
        })
    end

    local is_blacklisted, blacklist_err = token.is_blacklisted(conf, payload.jti)
    if blacklist_err then
        kong.log.err("Blacklist check failed: ", blacklist_err)
        metrics.blacklist_errors:inc(1)
        return kong.response.exit(500, {
            message = "Internal Server Error",
            error = "Failed to verify token status"
        })
    end

    if is_blacklisted then
        kong.log.warn("Token is blacklisted, jti: ", payload.jti)
        metrics.blacklisted_tokens:inc(1)
        return kong.response.exit(401, {
            message = "Unauthorized",
            error = "Token has been revoked"
        })
    end

    -- Count successful validation
    metrics.successful_validations:inc(1)

    kong.log.info("Token validated successfully for subject: ", payload.sub or "unknown")

    if payload.sub then
        kong.service.request.set_header("X-Auth-Subject", payload.sub)
    end

    -- Store the full payload in Kong's context for other plugins
    -- kong.ctx.shared.jwt_payload = payload
end

return plugin

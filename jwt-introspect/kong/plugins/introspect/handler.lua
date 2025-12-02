local redis = require("kong.plugins.introspect.redis")

local plugin = {
    PRIORITY = 1000,
    VERSION = "0.1.0-0"
}

function plugin:init_worker()
    kong.log.debug("saying hi from the 'init_worker' handler")
end

function plugin:access(conf)
    kong.log.debug("saying hi from the 'access' handler")
    kong.log.info(conf.key)

    local red, err = redis.get_redis_connection(conf)
    if not red then
        kong.log.err("Redis connection failed: ", err)
        return kong.response.exit(500, "Redis unavailable")
    end

    local res, err = red:get("some-key")
    if err then
        kong.log.err("Redis error: ", err)
    else
        kong.log.info("cached value: ", res)
    end

    redis.release(red)
end

return plugin

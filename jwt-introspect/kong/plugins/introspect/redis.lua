local redis = require "resty.redis"
local cjson = require "cjson.safe"

local _M = {}

function _M.get_redis_connection(conf)
    local red = redis:new()
    red:set_timeout(1000)

    local ok, err = red:connect(conf.redis_host, conf.redis_port)
    if not ok then
        return nil, "failed to connect: " .. (err or "")
    end

    if conf.redis_password then
        local ok, err = red:auth(conf.redis_password)
        if not ok then
            return nil, "failed to authenticate: " .. (err or "")
        end
    end

    if conf.redis_db then
        local ok, err = red:select(conf.redis_db)
        if not ok then
            return nil, "failed to select db: " .. (err or "")
        end
    end

    return red
end

function _M.release(red)
    red:set_keepalive(10000, 100)
end

return _M

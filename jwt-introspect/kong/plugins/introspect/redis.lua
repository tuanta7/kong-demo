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

local function set(red, k, v, ttl)
    local ok, err
    if ttl > 0 then
        ok, err = red:set(k, v, "EX", ttl)
    else
        ok, err = red:set(k, v)
    end

    if not ok then
        return nil, err or "failed to set redis cache"
    end

    return ok, err
end

function _M.set(conf, k, v, ttl)
    local red, err = _M.get_redis_connection(conf)
    if not red then
        return nil, err
    end

    local ok, err = set(red, k, v, ttl or 0)
    _M.release(red)

    if not ok then
        return nil, "Redis SET failed: " .. (err or "unknown")
    end

    return true, nil
end

-- setAll sets multiple key-value pairs one by one using the local set function
-- kvs: table of {key1, value1, key2, value2, ...} or {{key1, value1}, {key2, value2}, ...}
function _M.setAll(conf, kvs, ttl)
    if not kvs or #kvs == 0 then
        return nil, "no key-value pairs provided"
    end

    local red, err = _M.get_redis_connection(conf)
    if not red then
        return nil, err
    end

    local errors = {}

    -- Support both flat array {k1, v1, k2, v2} and nested array {{k1, v1}, {k2, v2}}
    if type(kvs[1]) == "table" then
        for i, pair in ipairs(kvs) do
            local ok, err = set(red, pair[1], pair[2], ttl or 0)
            if not ok then
                table.insert(errors, string.format("key '%s': %s", pair[1], err))
            end
        end
    else
        for i = 1, #kvs, 2 do
            local k, v = kvs[i], kvs[i + 1]
            local ok, err = set(red, k, v, ttl or 0)
            if not ok then
                table.insert(errors, string.format("key '%s': %s", k, err))
            end
        end
    end

    _M.release(red)

    if #errors > 0 then
        return nil, table.concat(errors, "; ")
    end

    return true, nil
end

function _M.get(conf, k)
    local red, err = _M.get_redis_connection(conf)
    if not red then
        return nil, err
    end

    local res, err = red:get(k)
    _M.release(red)

    if not res then
        return nil, "Redis GET failed: " .. (err or "unknown")
    end

    -- Normalize ngx.null to nil for consistency with local_cache
    if res == ngx.null then
        return nil, nil
    end

    return res, nil
end

function _M.exists(conf, key)
    local red, err = _M.get_redis_connection(conf)
    if not red then
        return nil, err
    end

    local res, err = red:exists(key)
    _M.release(red)

    if not res then
        return nil, "Redis EXISTS failed: " .. (err or "unknown")
    end

    if res == 1 then
        return true, nil
    end

    return false, nil
end

return _M

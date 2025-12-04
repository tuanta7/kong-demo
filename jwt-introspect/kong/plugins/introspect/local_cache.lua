local ngx_shared = ngx.shared

local _M = {}

_M.store = ngx_shared["kong"]

function _M.set(conf, k, v, ttl)
    local cache = _M.store
    if not cache then
        return nil, "shared dict not found"
    end

    local ok, err
    if ttl and ttl > 0 then
        ok, err = cache:set(k, v, ttl)
    else
        ok, err = cache:set(k, v)
    end

    if not ok then
        return nil, err or "failed to set cache"
    end

    return true, nil
end

function _M.get(conf, k)
    local cache = _M.store
    if not cache then
        return nil, "shared dict not found"
    end

    return cache:get(k)
end

-- setAll sets multiple key-value pairs one by one using the local set function
-- kvs: table of {key1, value1, key2, value2, ...} or {{key1, value1}, {key2, value2}, ...}
function _M.setAll(conf, kvs, ttl)
    if not kvs or #kvs == 0 then
        return nil, "no key-value pairs provided"
    end

    local errors = {}

    -- Support both flat array {k1, v1, k2, v2} and nested array {{k1, v1}, {k2, v2}}
    if type(kvs[1]) == "table" then
        for _, pair in ipairs(kvs) do
            local ok, err = _M.set(conf, pair[1], pair[2], ttl or 0)
            if not ok then
                table.insert(errors, string.format("key '%s': %s", pair[1], err))
            end
        end
    else
        for i = 1, #kvs, 2 do
            local k, v = kvs[i], kvs[i + 1]
            local ok, err = _M.set(conf, k, v, ttl or 0)
            if not ok then
                table.insert(errors, string.format("key '%s': %s", k, err))
            end
        end
    end

    if #errors > 0 then
        kong.log.warn("setAll completed with errors: ", table.concat(errors, "; "))
        return nil, table.concat(errors, "; ")
    end

    local cache = _M.store
    local count = type(kvs[1]) == "table" and #kvs or #kvs / 2
    kong.log.debug("setAll cached ", count, " keys with TTL ", ttl or 0)
    kong.log.debug(" | shm capacity: ", cache:capacity(), " | free space: ", cache:free_space())

    return true, nil
end

function _M.exists(conf, key)
    local cache = _M.store
    if not cache then
        return nil, "shared dict not found"
    end

    local value, err = cache:get(key)
    if err then
        return nil, err
    end

    if value ~= nil then
        return true, nil
    end

    return false, nil
end

return _M

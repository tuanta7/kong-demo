local cjson = require("cjson.safe")
local http = require("resty.http")
local pkey = require("resty.openssl.pkey")

local cache = require("kong.plugins.introspect.local_cache")

local KEY_PREFIX = "pk:"

local _M = {}

function _M.fetch_jwks(jwks_uri, timeout)
    timeout = timeout or 5000

    local httpc = http.new()
    httpc:set_timeout(timeout)

    local res, err = httpc:request_uri(jwks_uri, {
        method = "GET",
        headers = {
            ["Accept"] = "application/json"
        },
        ssl_verify = false -- Set to true in production
    })

    if not res then
        return nil, "Failed to fetch JWKS: " .. (err or "unknown error")
    end

    if res.status ~= 200 then
        return nil, "JWKS endpoint returned status: " .. res.status
    end

    local jwks, decode_err = cjson.decode(res.body)
    if not jwks then
        return nil, "Failed to parse JWKS: " .. (decode_err or "invalid JSON")
    end

    -- Handle both array format and {keys: [...]} format
    local keys = jwks.keys or jwks
    if type(keys) ~= "table" then
        return nil, "Invalid JWKS format: keys must be an array"
    end

    return keys
end

function _M.cache_all_jwks(conf, keys)
    local kvs = {}
    for _, jwk in ipairs(keys) do
        if jwk.kid then
            local key = KEY_PREFIX .. jwk.kid
            local json_jwk, encode_err = cjson.encode(jwk)
            if json_jwk then
                table.insert(kvs, key)
                table.insert(kvs, json_jwk)
            end
        end
    end

    if #kvs == 0 then
        return nil, "no valid JWKs to cache"
    end

    local ok, err = cache.setAll(conf, kvs, conf.cache_ttl)
    if not ok then
        return nil, err
    end

    kong.log.info("Cached ", #kvs / 2, " keys in local cache")
    return true
end

local function refresh_jwk_cache(conf)
    kong.log.info("Fetching JWKS from: ", conf.jwks_uri)
    local keys, err = _M.fetch_jwks(conf.jwks_uri)
    if not keys then
        return nil, err
    end

    local cache_ok, cache_err = _M.cache_all_jwks(conf, keys)
    if not cache_ok then
        kong.log.warn("Failed to cache JWKs in local cache: ", cache_err)
    end

    return keys
end

local function get_pkey(conf, kid)
    local key = KEY_PREFIX .. kid
    local res, err = cache.get(conf, key)
    if err then
        return nil, "Cache GET failed: " .. err
    end

    if not res then
        -- Key not found, not an error
        return nil, nil
    end

    -- res is already a JSON string from cache, pass it directly to pkey.new
    local pk, pkey_err = pkey.new(res, {
        format = "JWK"
    })
    if not pk then
        return nil, "Failed to create public key from JWK: " .. (pkey_err or "unknown error")
    end

    kong.log.debug("Cache hit for kid: ", kid)
    return pk
end

function _M.get_key(conf, kid)
    local cached_jwk, cache_err = get_pkey(conf, kid)
    if cached_jwk then
        kong.log.debug("Using cached JWK for kid: ", kid)
        return cached_jwk
    end

    if cache_err then
        kong.log.debug("Cache miss for kid: ", kid, " reason: ", cache_err)
    end

    -- Cache miss
    local keys, fetch_err = refresh_jwk_cache(conf)
    if not keys then
        return nil, fetch_err
    end

    local jwk = get_pkey(conf, kid)
    if not jwk then
        return nil, "No matching key found for kid: " .. kid
    end

    return jwk
end

return _M

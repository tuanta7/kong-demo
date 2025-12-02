local cjson = require("cjson.safe")
local http = require("resty.http")
local pkey = require("resty.openssl.pkey")
local bn = require("resty.openssl.bn")

local redis = require("kong.plugins.introspect.redis")
local utils = require("kong.plugins.introspect.utils")

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

local function jwk_to_pem_rsa(jwk)
    local n = utils.base64url_decode(jwk.n)
    local e = utils.base64url_decode(jwk.e)

    if not n or not e then
        return nil, "Invalid RSA JWK: missing n or e"
    end

    local n_bn = bn.from_binary(n)
    local e_bn = bn.from_binary(e)

    local pk, err = pkey.new({
        type = "RSA",
        n = n_bn,
        e = e_bn
    })

    if not pk then
        return nil, "Failed to create RSA public key: " .. (err or "unknown error")
    end

    return pk
end

local function jwk_to_pem_ed25519(jwk)
    local x = utils.base64url_decode(jwk.x)

    if not x then
        return nil, "Invalid Ed25519 JWK: missing x"
    end

    local pk, err = pkey.new({
        type = "Ed25519",
        pub = x
    })

    if not pk then
        return nil, "Failed to create Ed25519 public key: " .. (err or "unknown error")
    end

    return pk
end

function _M.jwk_to_pubkey(jwk)
    local kty = jwk.kty
    if kty == "RSA" then
        return jwk_to_pem_rsa(jwk)
    elseif kty == "OKP" and jwk.crv == "Ed25519" then
        return jwk_to_pem_ed25519(jwk)
    else
        return nil, "Unsupported key type: " .. (kty or "unknown")
    end
end

local function cache_jwk(red, key, json_jwk, ttl)
    if ttl > 0 then
        local ok, err = red:set(key, json_jwk, "EX", ttl)
        return ok, err
    end

    local ok, err = red:set(key, json_jwk)
    return ok, err
end

function _M.cache_all_jwks(conf, keys)
    local red, err = redis.get_redis_connection(conf)
    if not red then
        return nil, err
    end

    local cached_count = 0
    for _, jwk in ipairs(keys) do
        if jwk.kid then
            local key = KEY_PREFIX .. jwk.kid
            local json_jwk, encode_err = cjson.encode(jwk)
            if json_jwk then
                local ok, err = cache_jwk(red, key, json_jwk, conf.cache_ttl)
                if ok then
                    cached_count = cached_count + 1
                    kong.log.debug("Cached JWK for kid: ", jwk.kid)
                else
                    kong.log.warn("Failed to cache JWK for kid: ", jwk.kid, " error: ", err)
                end
            end
        end
    end

    redis.release(red)
    kong.log.info("Cached ", cached_count, " keys in Redis")
    return true
end

local function refresh_jwk_cache(conf, jwks_uri)
    kong.log.info("Fetching JWKS from: ", jwks_uri)
    local keys, err = _M.fetch_jwks(jwks_uri)
    if not keys then
        return nil, err
    end

    local cache_ok, cache_err = _M.cache_all_jwks(conf, keys)
    if not cache_ok then
        kong.log.warn("Failed to cache JWKs in Redis: ", cache_err)
    end

    return keys
end

local function get_key(conf, kid)
    local red, err = redis.get_redis_connection(conf)
    if not red then
        return nil, err
    end

    local key = KEY_PREFIX .. kid
    local res, err = red:get(key)
    redis.release(red)

    if not res then
        return nil, "Redis GET failed: " .. (err or "unknown")
    end

    if res == ngx.null then
        -- Key not found, not an error
        return nil, nil
    end

    local jwk, decode_err = cjson.decode(res)
    if not jwk then
        return nil, "Failed to decode cached JWK: " .. (decode_err or "invalid JSON")
    end

    local pkey, pkey_err = _M.jwk_to_pubkey(jwk)
    if not pkey then
        return nil, "Failed to load public key in jwk format: " .. pkey_err
    end

    kong.log.debug("Cache hit for kid: ", kid)
    return pkey
end

function _M.get_key(conf, jwks_uri, kid)
    local cached_jwk, cache_err = get_key(conf, kid)
    if cached_jwk then
        kong.log.debug("Using cached JWK for kid: ", kid)
        return cached_jwk
    end

    if cache_err then
        kong.log.debug("Cache miss for kid: ", kid, " reason: ", cache_err)
    end

    -- Cache miss - fetch all JWKs from endpoint
    local keys, fetch_err = refresh_jwk_cache(conf, jwks_uri)
    if not keys then
        return nil, fetch_err
    end

    local jwk = get_key(conf, kid)
    if not jwk then
        return nil, "No matching key found for kid: " .. kid
    end

    return jwk
end

return _M

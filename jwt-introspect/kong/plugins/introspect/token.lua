local cjson = require("cjson.safe")

local redis = require("kong.plugins.introspect.redis")
local key = require("kong.plugins.introspect.key")
local utils = require("kong.plugins.introspect.utils")

local BLACKLIST_PREFIX = "bl:"

local alg_map = {
    RS256 = {
        type = "RSA",
        digest = "sha256"
    },
    EdDSA = {
        type = "Ed25519",
        digest = nil
    }
}

local _M = {}

function _M.extract_token(auth_header)
    if not auth_header or auth_header == "" then
        return nil, "Missing Authorization header"
    end

    local token = auth_header:match("^[Bb]earer%s+(.+)$")
    if not token then
        return nil, "Invalid Authorization header format: expected 'Bearer <token>'"
    end

    return token
end

local function parse_jwt(token)
    if not token or token == "" then
        return nil, "Empty token"
    end

    local parts = {}
    for part in string.gmatch(token, "[^%.]+") do
        table.insert(parts, part)
    end

    if #parts ~= 3 then
        return nil, "Invalid JWT format: expected 3 parts, got " .. #parts
    end

    local header_json = utils.base64url_decode(parts[1])
    local payload_json = utils.base64url_decode(parts[2])
    local signature = utils.base64url_decode(parts[3])

    if not header_json then
        return nil, "Failed to decode JWT header"
    end
    if not payload_json then
        return nil, "Failed to decode JWT payload"
    end
    if not signature then
        return nil, "Failed to decode JWT signature"
    end

    local header, header_err = cjson.decode(header_json)
    if not header then
        return nil, "Failed to parse JWT header: " .. (header_err or "invalid JSON")
    end

    local payload, payload_err = cjson.decode(payload_json)
    if not payload then
        return nil, "Failed to parse JWT payload: " .. (payload_err or "invalid JSON")
    end

    return {
        header = header,
        payload = payload,
        signature = signature,
        signing_input = parts[1] .. "." .. parts[2],
        raw = {
            header = parts[1],
            payload = parts[2],
            signature = parts[3]
        }
    }
end

local function verify_signature(jwt, pubkey)
    local alg = jwt.header.alg
    local alg_info = alg_map[alg]

    if not alg_info then
        return false, "Unsupported algorithm: " .. (alg or "unknown")
    end

    if alg_info.type == "HMAC" then
        return false, "HMAC algorithms require symmetric key verification"
    end

    local ok, err = pubkey:verify(jwt.signature, jwt.signing_input, alg_info.digest)
    if err then
        return false, "Signature verification failed: " .. err
    end

    return ok
end

local function validate_claims(payload, options)
    options = options or {}
    local now = ngx.time()
    local clock_skew = options.clock_skew or 0

    if payload.exp then
        if type(payload.exp) ~= "number" then
            return false, "Invalid exp claim: must be a number"
        end
        if now > (payload.exp + clock_skew) then
            return false, "Token has expired"
        end
    elseif options.require_exp then
        return false, "Missing required exp claim"
    end

    if payload.iat then
        if type(payload.iat) ~= "number" then
            return false, "Invalid iat claim: must be a number"
        end
        if now < (payload.iat - clock_skew) then
            return false, "Token issued in the future"
        end
    end

    if payload.nbf then
        if type(payload.nbf) ~= "number" then
            return false, "Invalid nbf claim: must be a number"
        end
        if now < (payload.nbf - clock_skew) then
            return false, "Token is not yet valid"
        end
    end

    -- if options.issuer then
    --     if payload.iss ~= options.issuer then
    --         return false, "Invalid issuer: expected " .. options.issuer
    --     end
    -- end

    -- if options.audience then
    --     local aud = payload.aud
    --     local valid_aud = false

    --     if type(aud) == "string" then
    --         valid_aud = (aud == options.audience)
    --     elseif type(aud) == "table" then
    --         for _, a in ipairs(aud) do
    --             if a == options.audience then
    --                 valid_aud = true
    --                 break
    --             end
    --         end
    --     end

    --     if not valid_aud then
    --         return false, "Invalid audience"
    --     end
    -- end

    return true
end

function _M.validate_token(conf, token, options)
    options = options or {}

    local jwt, parse_err = parse_jwt(token)
    if not jwt then
        return nil, parse_err
    end

    local kid = jwt.header.kid
    if not kid then
        return nil, "Missing 'kid' claim in token payload header"
    end

    local pkey, pkey_err = key.get_key(conf, kid)
    if not pkey then
        return nil, pkey_err
    end

    local sig_valid, sig_err = verify_signature(jwt, pkey)
    if not sig_valid then
        return nil, sig_err or "Invalid signature"
    end

    local claims_valid, claims_err = validate_claims(jwt.payload, options)
    if not claims_valid then
        return nil, claims_err
    end

    return jwt.payload
end

function _M.is_blacklisted(conf, jti)
    if not jti then
        return nil, "Missing 'jti' claim in token payload"
    end

    local red, err = redis.get_redis_connection(conf)
    if not red then
        return nil, err
    end

    local key = BLACKLIST_PREFIX .. jti
    local res, err = red:exists(key)
    redis.release(red)

    if not res then
        return nil, "Redis EXISTS failed: " .. (err or "unknown")
    end

    if (res == 1) then
        kong.log.info("Token is blacklisted, jti: ", jti)
        return true
    end

    return nil
end

return _M

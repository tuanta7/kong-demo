local ngx_decode_base64 = ngx.decode_base64

local _M = {}

function _M.base64url_decode(input)
    if not input then
        return nil, "nil input"
    end

    -- Replace URL-safe characters
    local b64 = input:gsub("-", "+"):gsub("_", "/")

    -- Add padding if needed
    local padding = #b64 % 4
    if padding > 0 then
        b64 = b64 .. string.rep("=", 4 - padding)
    end

    return ngx_decode_base64(b64)
end

return _M

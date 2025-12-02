package = "jwt-introspect"
version = "0.1.0-0"

source = { url = "" }

description = {
  summary = "Token introspection plugin for Kong",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
  "lua-resty-openssl"
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.introspect.handler"] = "kong/plugins/introspect/handler.lua",
    ["kong.plugins.introspect.schema"] = "kong/plugins/introspect/schema.lua",
    ["kong.plugins.introspect.redis"] = "kong/plugins/introspect/redis.lua",
    ["kong.plugins.introspect.token"] = "kong/plugins/introspect/token.lua",
    ["kong.plugins.introspect.utils"] = "kong/plugins/introspect/utils.lua",
    ["kong.plugins.introspect.key"] = "kong/plugins/introspect/key.lua",
  }
}

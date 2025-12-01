package = "jwt-introspect"
version = "0.1.0"
source = { url = "" }
description = {
  summary = "Token introspection plugin for Kong",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.jwt-introspect.handler"] = "handler.lua",
    ["kong.plugins.jwt-introspect.schema"] = "schema.lua",
    ["kong.plugins.jwt-introspect.redis"] = "redis.lua",
  }
}

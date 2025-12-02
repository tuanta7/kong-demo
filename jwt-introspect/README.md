# Token Introspection Plugin

A small Kong plugin that performs token introspection. It validates JWTs (RS256 and Ed25519) and checks a token blacklist stored in Redis.

- Kong plugin name (module): `introspect`
- Directory name: `jwt-introspect`

## Installation

### 1. Build & install inside the image (recommended)

- The repository already includes a `Dockerfile` that runs `luarocks make` to install the plugin from the local rockspec. This places the plugin modules under Kong's Lua path so `require("kong.plugins.introspect.*")` works as expected.

- Build and run with docker-compose (from the `kong` folder):

  ```bash
  docker compose -f docker-compose.dbless.yml up --build
  ```

### 2. Mount the plugin as a volume (convenient for development)

- Mount the plugin folder into Kong's runtime Lua path and set `KONG_PLUGINS` to include `introspect`.

- Example `docker-compose` snippet (volume + env):

```yaml
volumes:
  - ../jwt-introspect/kong/plugins/introspect:/usr/local/share/lua/5.1/kong/plugins/introspect

environment:
  KONG_PLUGINS: bundled,introspect
```

Module names and rockspec

- The rockspec (`jwt-introspect-0.1.0.rockspec`) maps Lua module names to source files, for example:

```lua
["kong.plugins.introspect.handler"] = "kong/plugins/introspect/handler.lua"
```

- That means Kong will expect `require("kong.plugins.introspect.redis")` and the `KONG_PLUGINS` environment variable should list `introspect` (the module name), not the package name `jwt-introspect`.

### Configuration

- In a declarative `kong.yml` or when adding the plugin, use the plugin name `introspect`:

```yaml
plugins:
- name: introspect
    config:
        key: "<verification-key>"
        redis_host: ["redis"]
        redis_port: 6379
```

### Notes

- Use `luarocks make` during image build to install the plugin from the local rockspec. `luarocks pack` only packages the code into a `.rock` file and does not install it.
- Ensure the module names you `require()` match the module keys in the rockspec.

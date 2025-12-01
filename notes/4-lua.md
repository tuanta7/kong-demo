# Dependencies Management in Lua 

- [Luarocks Docs](https://github.com/luarocks/luarocks/tree/main/docs)
- [Rockspec Format](https://github.com/luarocks/luarocks/blob/main/docs/rockspec_format.md) 

## 1. LuaRocks

LuaRocks is a package manager for the Lua programming language that provides a standard format for distributing Lua modules (similar to how npm manages packages for Node.js/JavaScript)

### 1.1. Rockspec File

A rockspec is actually a Lua file, but it is loaded in an empty environment, so there are no Lua functions available. A skeleton for a basic rockspec looks can be written by hand or generated. LuaRocks offers these commands for creating rockspec files.

```sh
# Write a template for a rockspec file
luarocks write_rockspec --lua-versions=5.1

# Generate a new Rockspec version derived from an existing one
luarocks new_version
```

An example Rockspec structure is shown below:

```lua
package = "template"
version = "0.3-1"

source = {
  url = "git://github.com/dannote/lua-template.git"
}

description = {
  summary = "The simplest Lua template engine in just a few lines of code",
  homepage = "https://github.com/dannote/lua-template",
  maintainer = "Danila Poyarkov <dannotemail@gmail.com>",
  license = "MIT"
}

dependencies = {
  "lua >= 5.0"
}

build = {
  type = "builtin",
  modules = {
    ["template"] = "template.lua"
  },
  install = {
    bin = { "templatec" }
  }
}
```

Once the Rockspec is present in the plugin repository, the plugin can be packaged through the LuaRocks toolchain.

### 1.2. Install Dependencies

```sh
# Install dependencies manually 
luarocks install lua-resty-jwt

# Install and check if listed dependencies are installed
luarocks make
```

There is NO automatic checking mechanism that validates whether the modules that require() in the code are actually available.

### 1.3. Syntaxes & Conventions
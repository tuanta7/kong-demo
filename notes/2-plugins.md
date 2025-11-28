# Kong Plugins

Reference: [Plugins - Kong Gateway](https://developer.konghq.com/gateway/entities/plugin)

Kong Gateway is a Lua application designed to load and execute **modules**. These modules, called plugins, allow you to add more features to your implementation.

## 1. Concepts

A plugin allows you to inject custom logic at several entrypoints in the lifecycle of a request, response, or TCP stream connection as it is proxied by Kong Gateway.

### 1.1. Contexts

The following functions are used to implement plugin logic at various entry-points of Kong Gateway’s execution life-cycle

- **init_worker**: Executed upon every Nginx worker process’s startup.
- **rewrite**: Executed for every request upon its reception from a client as a rewrite phase handler.
- **access**: Executed for every request from a client and before it is being proxied to the upstream service.
- **response**: Executed after the whole response has been received from the upstream service, but before sending any part of it to the client.
- etc.

> [!NOTE]
> All plugin functions—apart from `init_worker` and `configure` receive a single parameter (conf) supplied by Kong Gateway. This parameter is a Lua table that represents the plugin’s configuration, containing values defined by end-users based on the rules in `schema.lua`.
>
> In contrast, the `configure` function is invoked with an array containing all active configurations of the plugin.

### 1.2. Scopes

Each plugin can run globally, or be scoped to some combination of Gateway Services, Routes, Consumers and Consumer Groups

#### Global scope

A global plugin is not associated to any Service, Route, Consumer, or Consumer Group is considered global, and will be run on every request, regardless of any other configuration.

#### Plugin precedence

A plugin can have multiple instances in the same configuration. Different instances can be used to apply the plugin to various entities, combinations of entities, or even globally.

### 1.3. Priority

All of the plugins bundled with Kong Gateway have a static priority. This can be adjusted dynamically using the plugin’s `ordering` configuration parameter.

## 2. Custom Plugin (Lua)

There are several plugins built by the community that can be used, in addition to the 90+ official plugins available on the [plugin hub](https://developer.konghq.com/plugins/)

Kong provides a development environment for developing plugins, including Plugin Development Kits (or PDKs), database abstractions, migrations, and more.

### 2.1. Luarock

LuaRocks is a package manager for the Lua programming language that provides a standard format for distributing Lua modules (similar to how npm manages packages for Node.js/JavaScript)

### 2.2. Syntaxes & Conventions

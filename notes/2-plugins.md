# Kong Plugins

Reference: [Plugins - Kong Gateway](https://developer.konghq.com/gateway/entities/plugin/#:~:text=How%20do%20plugins%20work%3F,is%20proxied%20by%20Kong%20Gateway.)

Kong Gateway is a Lua application designed to load and execute **modules**. These modules, called plugins, allow you to add more features to your implementation.

- A plugin allows you to inject custom logic at several entrypoints in the lifecycle of a request, response, or TCP stream connection as it is proxied by Kong Gateway.
- There are several plugins built by the community that can be used, in addition to the 90+ official plugins available on the [plugin hub](https://developer.konghq.com/plugins/)

## 1. Concepts

### 1.1. Contexts

### 1.2. Scopes

### 1.3. Priority

## 2. Custom Plugin (Lua)

Kong provides a development environment for developing plugins, including Plugin Development Kits (or PDKs), database abstractions, migrations, and more.

### 2.1. Luarock

LuaRocks is a package manager for the Lua programming language that provides a standard format for distributing Lua modules (similar to how npm manages packages for Node.js/JavaScript)

### 2.2. Syntaxes & Conventions
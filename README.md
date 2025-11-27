# kong-demo

🙉 Notes and demonstration of Kong Gateway and its plugins.

- Install: [Install Kong Gateway](https://developer.konghq.com/gateway/install/#docker)
- Official Kong plugin template: [Kong/kong-plugin](https://github.com/Kong/kong-plugin)
- Custom plugin guide: [Custom plugins](https://developer.konghq.com/custom-plugins/)
- Typedefs: [Source code](https://github.com/Kong/kong/blob/master/kong/db/schema/typedefs.lua)

## 1. Modes

### Traditional Mode

### Declarative Mode (DB-less)

Kong can operate with no database, using a single YAML or JSON file that defines all entities. Entity management occurs by editing the file then reloading the gateway

## 2. Kong Ingress Controller

In Kubernetes environments, Kong entities can be defined using Kubernetes resources such as KongIngress, KongPlugin, KongConsumer, HTTPRoute (Gateway API), Ingress. These CRDs are translated by the Kong Ingress Controller into Kong configuration without using the Admin API directly.

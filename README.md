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

## 3. Kong Ecosystem

The core of the ecosystem is the API gateway, a reverse proxy that manages, routes, and configures requests to APIs.

### 3.1. Konnect

Kong Konnect is a unified API platform that manages APIs, LLMs, events, and microservices, consolidating API and connectivity management. It is delivered as a SaaS control plane for Kong Gateway and associated services.

- Konnect provides several built-in applications that run on top of the Konnect platform to help manage, monitor, and secure your API ecosystem, as well as provide a customizable developer experience.

### 3.2. Insomnia (Postman Alternative)

Insomnia is an open source desktop application that simplifies designing, debugging, and testing APIs.

### 3.3. decK

decK is a command line tool that facilitates API Lifecycle Automation (APIOps) by offering a comprehensive toolkit of commands designed to orchestrate and automate the entire process of API delivery.

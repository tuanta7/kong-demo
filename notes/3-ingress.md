# Kong Ingress Controller

Reference: [Kong Ingress Controller (KIC)](https://developer.konghq.com/kubernetes-ingress-controller/)

The Kong Ingress Controller (KIC) is a Kubernetes controller that allows \*\*Kong Gateway to function as the Ingress layer of a Kubernetes cluster. It converts Kubernetes networking resources into Kong configuration.

## Plugin Resource

A plugin is defined with a KongPlugin CRD. This plugin can then be attached to an Ingress

```yml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: rate-limit-plugin
plugin: rate-limiting
config:
  minute: 100
  policy: local
```

The plugin is attached using the annotation: konghq.com/plugins

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    konghq.com/plugins: rate-limit-plugin
spec:
  ingressClassName: kong
  rules:
    - http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 80
```

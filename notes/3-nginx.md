# NGINX (engine-x)

## 1. Concepts 

## 2. Directives

Reference: [Kong Gateway | NGINX directives](https://developer.konghq.com/gateway/nginx-directives/)

In NGINX, directives are instructions that are used to configure the web server. They are typically specified in the `nginx.conf` configuration file, located in the `/etc/nginx/` director. In **Kong**, NGINX directives can be used in the `kong.conf` file.

- Entries in that are prefixed with `nginx_http_`, `nginx_proxy_`, or `nginx_admin_` are converted to NGINX directives.
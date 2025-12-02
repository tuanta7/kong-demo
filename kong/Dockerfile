FROM kong:3.9-ubuntu

USER root

WORKDIR /plugins/jwt-introspect
RUN apt-get update -yq && apt-get install -yqq curl

COPY jwt-introspect /plugins/jwt-introspect

# builds and installs a rock from a local .rockspec file and source code
# it places the compiled Lua files into the correct directory within the container such as /usr/local/share/lua/5.1/ 
RUN luarocks make

USER kong
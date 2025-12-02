FROM kong:3.8

USER root

WORKDIR /plugins/jwt-introspect
COPY jwt-introspect /plugins/jwt-introspect

# builds and installs a rock from a local .rockspec file and source code
# it places the compiled Lua files into the correct directory within the container such as /usr/local/share/lua/5.1/ 
RUN luarocks make

USER kong
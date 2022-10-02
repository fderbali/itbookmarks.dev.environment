##
# Build the specified service's image or all of them.
# see lib/build.sh
##
if [[ ${args[service]} ]]; then
    info "Building '${args[service]}' service..."
    docker_compose_build "${args[service]}"
else
    info "Building environment..."
    docker_compose_build
fi

##
# Initialize the environment
# see lib/
##
# Make sure all other containers are closed
stop_running_containers

# Initialize
info "Initializing the local environment..."
env \
    ; validate_host_file \
    ; repositories \
    ; docker_compose_down -v \
    ; docker_compose_build \
    
    # Services init here
    # ...

if [ ! -f .docker/nginx/certs/{TEMPLATE_DOMAIN}.crt ]; then
    ssl_generate
else
    success "Using existing self-signed certificate. Run 'itbookmarks ssl generate' and 'itbookmarks ssl install' if you need a new one."
fi

docker_compose_start \
    ; ssl_install \
    ; ssl_service_available

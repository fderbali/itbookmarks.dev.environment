##
# Update the local environment:
#  * pull the environment's latest changes;
#  * clone or update each application's repository;
#  * (re)build the images;
#  * run the database migrations;
#  * install the dependencies;
#  * (re)install the ssl certificate.
##
info "Updating the local environment..."
git pull && repositories

# Rebuild the environment
stop_running_containers
if [[ ${args[--rebuild]} ]]; then
    info "Rebuilding via docker compose..." 
    docker_compose_build
fi

# Update services
# ...

# Restart the environment
info "Restarting the local environment..."
docker_compose_start

# Re-install the SSL
if [[ ${args[--ssl]} ]]; then
    ssl_install
fi

check
ssl_service_available

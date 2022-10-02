##
# Stop and destroy all containers.
# see lib/down.sh
##
info "Stopping the local environment and removing all containers..."

if [[ ${args[--volumes]} ]]; then
    docker_compose_down -v
else
    docker_compose_down
fi

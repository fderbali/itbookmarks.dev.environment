##
# (Re)Create and start the containers and volumes.
##

# Make sure all other containers are closed
stop_running_containers

# Start the environment
info "Starting the local environment..."
docker_compose_start \
    ; check \
    ; ssl_service_available
##
# Restart all containers or one container
##
docker_compose_restart "${@:1}" \
    ; check \
    ; ssl_service_available

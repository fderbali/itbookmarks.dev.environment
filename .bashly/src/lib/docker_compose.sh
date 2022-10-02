##
# Build the specified service's image or all of them.
##
docker_compose_build () {
    docker compose build "${@:1}"
}

##
# Stop and destroy all containers.
#
# Options:
#  --volumes, -v   also destroy volumes
##
docker_compose_down () {
    docker compose down "${@:1}"
}

##
# (Re)Create and start the containers and volumes.
##
docker_compose_start () {
    docker compose up -d
}

##
# Restart the containers.
##
docker_compose_restart () {
    docker compose restart "${@:1}"
}

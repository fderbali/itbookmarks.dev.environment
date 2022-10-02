##
# Run the specified service's initialisation script.
##
service_init () {
    info "Running ${1}'s initialization script..."
    docker compose run -u root --rm --entrypoint="//opt/files/init.sh" "$1"
}

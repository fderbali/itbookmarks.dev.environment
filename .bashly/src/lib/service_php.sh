##
# Run a composer command on the specified service.
##
service_composer () {
    info "Running composer ${@:2} on ${1}..."
    docker compose run --rm ${1} composer "${@:2}"
}

##
# Run PHPUnit on the specified service.
##
service_phpunit () {
    info "Running phpunit ${@:2} on ${1}..."
    docker compose run --rm --entrypoint="vendor/bin/phpunit" "$1" "${@:2}" -v --testdox
}

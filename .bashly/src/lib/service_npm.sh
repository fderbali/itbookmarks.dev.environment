##
# Run a npm command on the specified service.
##
service_npm () {
    info "Running npm ${@:2} on ${1}..."
    docker compose run --rm ${1} npm --prefix "//var/www" "${@:2}"
}
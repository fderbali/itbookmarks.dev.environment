##
# Run an artisan command on the specified service.
##
service_laravel_artisan () {
    info "Running artisan ${@:2} on ${1}..."
    docker compose run --rm ${1} php artisan "${@:2}"
}

##
# Run the api's database migrations.
##
service_laravel_migrate () {
    service_laravel_artisan $1 "${@:2}"
}
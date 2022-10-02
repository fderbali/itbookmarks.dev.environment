##
# Display and tail the logs.
##
if [[ ${args[service]} ]]; then
    docker compose logs "${args[service]}"
else
    docker compose logs
fi

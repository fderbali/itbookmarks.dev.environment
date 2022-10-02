##
# Destroy docker containers, volumes and images.
##
echo
read -p "This will remove containers, volumes as well as images. Are you sure? [y/N]: " -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1; fi
docker compose down -v --rmi all

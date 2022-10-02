##
# Fix SSL container issues.
##
info "Fixing the SSL..."
docker compose rm -f -s -v nationalmap \
    ; docker compose rm -f -s -v nginx \
    ; docker compose up -d \
    ; ssl_generate \
    ; ssl_install

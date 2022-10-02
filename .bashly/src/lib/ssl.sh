##
# Generate a Certificate Authority as well as a wildcard certificate (*.$(config_get test_domain)).
##
ssl_generate () {
    info "Generating new self-signed certificate..."
    rm -Rf .docker/nginx/certs/$(config_get test_domain).*
    docker compose run --rm nginx sh -c "cd /etc/nginx/certs && touch openssl.cnf && cat /etc/ssl/openssl.cnf > openssl.cnf && echo \"\" >> openssl.cnf && echo \"[ SAN ]\" >> openssl.cnf && echo \"subjectAltName=DNS.1:$(config_get test_domain),DNS.2:*.$(config_get test_domain)\" >> openssl.cnf && openssl req -x509 -sha256 -nodes -newkey rsa:4096 -keyout $(config_get test_domain).key -out $(config_get test_domain).crt -days 3650 -subj \"/CN=*.$(config_get test_domain)\" -config openssl.cnf -extensions SAN && rm openssl.cnf"
}

##
# Install the self-signed certificate on the local machine
# (when possible), as well as in the relevant containers.
#
# Will install the certificate on all containers by default,
# or on the specified list of containers.
##
ssl_install () {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        info "Installing the self-signed certificate on your local machine..."
        sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain .docker/nginx/certs/$(config_get test_domain).crt
    elif [[ "$OSTYPE" == "linux-gnu" ]]; then
        info "Installing the self-signed certificate on your local machine..."
        sudo ln -s "$(pwd)/.docker/nginx/certs/$(config_get test_domain).crt" /usr/local/share/ca-certificates/$(config_get test_domain).crt
        sudo update-ca-certificates
        echo "Ensuring Chrome accepts it..."
        sudo apt-get install libnss3-tools
        certutil -D -d sql:$HOME/.pki/nssdb -n $(config_get test_domain)
        certutil -d sql:$HOME/.pki/nssdb -A -t "CT,C,C" -n $(config_get test_domain) -i /etc/ssl/certs/$(config_get test_domain).pem
    else
        call_to_action "Could not install the self-signed certificate on your local machine, please do it manually!"
    fi

    if [ $# -eq 0 ]; then
        services=($(config_get ssl_services))
    else
        services=$@
    fi

    for i in ${services[@]}
    do
        info "Adding the self-signed certificate to service $i..."
        docker compose exec ${i} update-ca-certificates
    done
}

##
# Check if SSL services are available through http
##
ssl_service_available () {
    info "Waiting for services to get available..."
    for i in $(config_get ssl_services);
        do

        count=1
        while [ $count -le 10 ]; do
            response=$(curl --write-out '%{http_code}' --silent --output /dev/null --connect-timeout 5 https://$i.$(config_get test_domain))
            if [[ $response == "200" || $response == "404" ]]; then
                success "$i is available at https://$i.$(config_get test_domain)"
                break
            fi

            if [[ $response == "000" ]]; then
                error "$i is unavailable: either the SSL certificate is not installed locally or nginx is not available"
                break
            fi

            sleep 5
            ((count++))
        done

        if [ "$count" -ge 10 ]; then
            error "$i is unavailable: verification exceeded 10 attempt"
        fi
    done
}
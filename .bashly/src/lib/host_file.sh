##
# Validate if the host file contains test domain
##
validate_host_file () {
    if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "linux-gnu" ]]; then
        host_file="/etc/hosts"
    else
        host_file="C:\Windows\System32\drivers\etc\hosts"
    fi

    if grep -Fq "$(config_get test_domain)" $host_file
    then
        success "Host file valid."
    else
        call_to_action "Please add the following line to your host file (${host_file}):"

        host_line="127.0.0.1  "
        for service in "$(config_get ssl_services)";
        do
            host_line="${host_line} ${service}.$(config_get test_domain)"
        done

        echo ${host_line}
    fi
}

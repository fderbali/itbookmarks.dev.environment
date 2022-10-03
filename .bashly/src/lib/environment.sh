##
# Check the status of the environment
##
check () {
    info "Checking status of environment..."
    updated=true

    if [[ $(git status --untracked-files=no) == *"Your branch is behind"* ]]; then
        updated=false
    fi

    for repository in "$(config_get repositories)";
    do
        if [[ $(git -C "src/$repository" status --untracked-files=no) == *"Your branch is behind"* ]]; then
            updated=false
        fi
    done

    if [[ "$updated" == true ]]; then
        success "Your environment is up to date!"
    else
        call_to_action "Your environment is out of date, please do a '{TEMPLATE_COMMAND} update'"
    fi

    # Also validate host file
    validate_host_file
}

##
# Create .env file from .env.example.
##
env () {
    if [ ! -f .env ]; then
        info "Copying .env.example file to .env..."
        cp .env.example .env
    fi
}

##
# Display an information message.
##
info () {
    echo
    echo "$(tput setaf 7)-> $1 $(tput sgr 0)"
}

##
# Display a call to action message
##
call_to_action () {
    echo "$(tput setaf 3)! $1 $(tput sgr 0)"
}

##
# Display a success message
##
success () {
    echo "$(tput setaf 2)~ $1 $(tput sgr 0)"
}

##
# Display an error message
##
error () {
    echo "$(tput setaf 1)Error: $1 $(tput sgr 0)"
}

##
# Clone or update all repositories or the specified ones.
##
repositories () {
    for repository in $(config_get repositories);
    do
        if [ -d "src/$repository" ]; then
            info "Pruning and pulling repository $(config_get repositories_prefix).$repository..."
            git -C "src/$repository" prune origin
            git -C "src/$repository" pull origin || git -C "src/$repository" pull origin dev
        else
            call_to_action "Repository not initialized, cloning..." 
            git clone "git@github.com:fderbali/$(config_get repositories_prefix).$repository.git" "src/$repository"
        fi
    done
}

##
# Check for running containers and stop them
##
stop_running_containers () {
    running_containers=$(docker container ls -f "status=running" -q)
    if [[ ${running_containers} ]]; then
        call_to_action "Containers are currently running"
        info "Stopping containers..."
        docker stop ${running_containers}
        success "Containers stopped!"
    fi
}

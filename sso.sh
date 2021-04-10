function aws_sso_login {
    local profile="${1:-default}"
    
    # check if profile exists
    if [ "$(cat ~/.aws/config | grep "profile" | grep "\[profile ${profile}\]" | wc -l)" != '1' ] ; then
        echo "Error: Profile now found"
        return 1
    fi

    # Use a profile as defined in $HOME/.aws/config
    export AWS_DEFAULT_PROFILE="$profile"
    if aws sts get-caller-identity 2>&1 1>/dev/null ; then
        # If this successed then the access keys have been
        # fetched (or used from cache) & the profile is ready to go
        true
    else
        # Otherwise, no session so need to login
        aws sso login
    fi

    echo "Successfully switched profiles to: ${AWS_DEFAULT_PROFILE}"
}

## Completions
# zsh use `autoload -U +X bashcompinit && bashcompinit` or PR a working completion

if type complete > /dev/null; then
    _aws_sso_login() {
        local cur opts
        cur="${COMP_WORDS[COMP_CWORD]}"
        opts="$(cat ~/.aws/config | grep "profile" | sed -r 's/^\[profile (.*)]$/\1/' | paste -sd ' ')"
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    }
    complete -F _aws_sso_login aws_sso_login
fi

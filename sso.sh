function _aws_list_profiles {
    cat ~/.aws/config | grep '^\[' | sed -e 's/profile *//' | sed -r 's/\[(.*)\]/\1/'
}

function aws_sso_login {
    local profile="${1:-default}"
    
    # check if profile exists
    if _aws_list_profiles | grep "^${profile}$" > /dev/null ; then
        # pass - successful
        true
    else
        echo "Error: Profile ($profile) not found"
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
# zsh use must have `autoload -U +X compinit && compinit` enabled

if type compdef 2> /dev/null 1> /dev/null; then
    _aws_sso_login() {
        _arguments -C "1: :($(_aws_list_profiles))"
    }
    compdef _aws_sso_login aws_sso_login
elif type complete 2> /dev/null 1> /dev/null; then
    _aws_sso_login() {
        local cur opts
        cur="${COMP_WORDS[COMP_CWORD]}"
        opts="$(_aws_list_profiles | paste -s -d ' ' -)"
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    }
    complete -F _aws_sso_login aws_sso_login
fi

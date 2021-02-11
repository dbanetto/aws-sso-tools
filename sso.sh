function aws_sso_login {
    # Use a profile as defined in $HOME/.aws/config
    export AWS_DEFAULT_PROFILE="$1"
    aws sso login
}

#!/usr/bin/env bash

##
# This file is part of the `phpenv` package.
#
# Copyright (c) 2011 Christoph Hochstrasser
# Copyright (c) 2016 Rob Frawley <rmf@src.run>
#
# For the full copyright and license information, view the LICENSE.md
# file distributed with this source code.
##

SCRIPT_REAL_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}" 2> /dev/null)" && pwd)"
REMOTE_RB_ENV="https://github.com/sstephenson/rbenv.git"
REMOTE_PHP_BLD="https://src.run/multi-env/php-build.git"
REMOTE_PHP_CFG="https://src.run/multi-env/php-config.git"

source "$SCRIPT_REAL_PATH/../lib/bright/bright.bash"

out_prefix()
{
    bright_out_builder "$(basename $0)" "color:brown"
    echo -n " "
}

out_line()
{
    out_prefix
    echo $1
}

out_title()
{
    out_prefix
    bright_out_builder " $1 " "control:style bold" "control:style reverse"
    echo
}

out_instruction()
{
    out_prefix
    bright_out_builder ">   $1" "color:magenta" "control:style bold"
    echo
}

out_state_start()
{
    out_prefix
    echo -n "${1:-starting operation} ... "
}

out_state_done_success()
{
    bright_out_builder " ${1:-okay} " "color:white" "color_bg:green" "control:style bold"
    echo
}

out_state_done_error()
{
    bright_out_builder " ${1:-fail} " "color:white" "color_bg:red"
    echo
}

out_state_done_okay()
{
    bright_out_builder "${1:-done}" "color:green" "control:style bold"
    echo
}

out_state_done()
{
    case "$1" in
        0 ) out_state_done_okay ;;
        * ) out_state_done_error ;;
    esac
}

phpenv_script()
{
    local root="$1"

    cat <<SH
#!/usr/bin/env bash
export PHPENV_ROOT=\${PHPENV_ROOT:-'$root'}
export RBENV_ROOT="\$PHPENV_ROOT"
exec "\$RBENV_ROOT/libexec/rbenv" "\$@"
SH
}

create_phpenv_bin()
{
    local install_path="$1"

    phpenv_script "$install_path" > "$install_path/bin/phpenv"
    chmod +x "$install_path/bin/phpenv"
}

update_phpenv()
{
    local install_path="$1"
    local working_path=$(pwd)

    out_state_start "Updating rbenv $REMOTE_RB_ENV"
    cd "$install_path"
    git pull origin master > /dev/null 2>&1
    out_state_done $?
    cd "$working_path"
}

update_plugin()
{
    local remote="$2"
    local plugin="$3"
    local install_path="$1/plugins/$plugin"
    local working_path=$(pwd)

    out_state_start "Updating plugin $remote"
    cd "$install_path"
    git pull origin master > /dev/null 2>&1
    out_state_done $?
    cd "$working_path"
}

get_phpenv()
{
    local install_path="$1"

    out_state_start "Cloning rbenv $REMOTE_RB_ENV"
    git clone "$REMOTE_RB_ENV" "$install_path" > /dev/null 2>&1
    out_state_done $?
}

get_plugin()
{
    local remote="$2"
    local plugin="$3"
    local install_path="$1/plugins/$plugin"
    local working_path=$(pwd)

    out_state_start "Cloning plugin $plugin $remote"
    git clone "$remote" "$install_path" > /dev/null 2>&1
    out_state_done $?
    cd "$working_path"
}

do_substitutions()
{
    local install_path="$1"

    sed -i -e 's/rbenv/phpenv/g' "$install_path"/completions/rbenv.{bash,zsh}
    sed -i -s 's/\.rbenv-version/.phpenv-version/g' "$install_path"/libexec/rbenv-local
    sed -i -s 's/\.rbenv-version/.phpenv-version/g' "$install_path"/libexec/rbenv-version-file
    sed -i -s 's/\.ruby-version/.php-version/g' "$install_path"/libexec/rbenv-local
    sed -i -s 's/\.ruby-version/.php-version/g' "$install_path"/libexec/rbenv-version-file
    sed -i -e 's/\(^\|[^/]\)rbenv/\1phpenv/g' "$install_path"/libexec/rbenv-init
    sed -i -e 's/\phpenv-commands/rbenv-commands/g' "$install_path"/libexec/rbenv-init
    sed -i -e 's/\Ruby/PHP/g' "$install_path"/libexec/rbenv-which
}

main()
{
    if [ -z "$PHPENV_ROOT" ]; then
        PHPENV_ROOT="$HOME/.phpenv"
    fi

    out_title "PHPENV Installer"
    out_line "Using installation path $PHPENV_ROOT"

    if [ -d $PHPENV_ROOT ]; then
        update_phpenv "$PHPENV_ROOT"
        update_plugin "$PHPENV_ROOT" "$REMOTE_PHP_BLD" "php-build"
        update_plugin "$PHPENV_ROOT" "$REMOTE_PHP_CFG" "php-config"
    else
        get_phpenv "$PHPENV_ROOT"
        get_plugin "$PHPENV_ROOT" "$REMOTE_PHP_BLD" "php-build"
        get_plugin "$PHPENV_ROOT" "$REMOTE_PHP_CFG" "php-config"
    fi

    out_state_start "Performing string replacements"
    do_substitutions  "$PHPENV_ROOT"
    out_state_done $?

    out_state_start "Creating phpenv binary file"
    create_phpenv_bin "$PHPENV_ROOT"
    out_state_done $?

    out_instruction
    out_instruction "# Add to $HOME/.bashrc to activate PHPENV"
    out_instruction
    out_instruction "export PATH=\"${PHPENV_ROOT}/bin:"'$PATH"'
    out_instruction 'eval "$(phpenv init -)"'
    out_instruction
    out_line "Completed installation"
}

main

# EOF

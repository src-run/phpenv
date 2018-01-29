#!/usr/bin/env bash

##
# This file is part of the `src-run/phpenv` package.
#
# Copyright (c) 2016-2018 Rob Frawley <rmf@src.run>
#
# For the full copyright and license information, view the LICENSE.md
# file distributed with this source code.
##

declare PHPENV_INSTALLER_REALPATH="$(cd "$(dirname "${BASH_SOURCE[0]}" 2> /dev/null)" && pwd)"

declare -A PHPENV_INST_DEPENDS=(
    [bright-library]="$PHPENV_INSTALLER_REALPATH/../lib/bright/bright.bash"
)

declare -A PHPENV_INST_REMOTES=(
    [rbenv]="https://github.com/sstephenson/rbenv.git"
    [php-build]="https://github.com/php-build/php-build.git"
    [php-conf]="https://github.com/src-run/php-conf.git"
)

readonly PHPENV_REMOTE_RBENV="https://github.com/sstephenson/rbenv.git"
readonly PHPENV_REMOTE_PHPBLD="https://github.com/php-build/php-build.git"
readonly PHPENV_REMOTE_PHPCFG="https://github.com/src-run/php-conf.git"

out_nl()
{
    echo -en "\n"
}

out()
{
    echo -n "${1:-}"
    [ "${2:-false}" == "true" ] && out_nl
}

out_prefix()
{
    [ -z $out_prefix_count ] && count=0
    out_prefix_count=$((($out_prefix_count + 1)))

    bright_out_builder "[$(basename $0):$(printf "%03d" $out_prefix_count)]" \
        "color:black" "color_bg:white" "control:style reverse"
    out " " false
}

out_line()
{
    out_prefix
    bright_out_builder " --- " "color:magenta" "control:style bold"
    out " $1" true
}

out_title()
{
    out_prefix
    bright_out_builder " +++ " "control:style bold" "control:style reverse"
    out " PHPENV INSTALLER AND UPDATER"
    out_nl
}

out_error()
{
        out_prefix
        bright_out_builder " !!! " "color_bg:red"
        bright_out_builder " $1" "color:red" "control:style bold"
        out_nl
}

out_instructions()
{
    bright_out_builder "$1" "color:white" "control:style bold"
    out_nl
}

out_state_start()
{
    out_prefix
    bright_out_builder " --- " "color:magenta" "control:style bold"
    out " ${1:-starting operation} ... " false
}

out_state_done_success()
{
    bright_out_builder " ${1:-okay} " "color:white" "color_bg:green" "control:style bold"
    out_nl
}

out_state_done_error()
{
    bright_out_builder " ${1:-fail} " "color:white" "color_bg:red"
    out_nl
}

out_state_done_okay()
{
    bright_out_builder "${1:-done}" "color:green" "control:style bold"
    out_nl
}

out_state_done()
{
    case "$1" in
        0 ) out_state_done_okay ;;
        * ) out_state_done_error ;;
    esac
}

out_prompt()
{
    local question="$1"
    local default="${2:-}"
    local boolean="${3:-true}"
    local input

    if [[ "$default" == "true" ]]; then default="y"; fi
    if [[ "$default" == "false" ]]; then default="n"; fi

    while [ true ]; do
        out_prefix
        bright_out_builder " ??? " "color_bg:magenta" "control:style bold"
        if [[ "$default" == "n" ]]; then
            out " $1? [y/N]: " false
        elif [[ "$default" == "y" ]]; then
            out " $1? [Y/n]: " false
        fi

        if [ -n "$NON_INTERACTIVE" ]; then
            echo "(non-interactive $default)"
        else
            read input
        fi

        if [ ! -n "$input" ]; then
            input="$default"
        fi

        case "$input" in
            y*|Y*) return 0 ;;
            n*|N*) return 1 ;;
        esac
    done

    out_nl
}

get_build_deps()
{
    sudo -p "Password to install build dependencies: " echo -n ""
    out_state_start "Updating system package cache"
    sudo apt-get update -qq
    out_state_done $?

    out_state_start "Resolving system build dependencies"
    sudo apt-get build-dep -qq -y --force-yes php5
    out_state_done $?
}

phpenv_script()
{
    local root="$1"

    cat <<SH
#!/usr/bin/env bash
export PHPENV_ROOT=\${PHPENV_ROOT:-'$root'}
exec "\$PHPENV_ROOT/libexec/phpenv" "\$@"
SH
}

create_phpenv_bin()
{
    local install_path="$1"
    local result=0

    out_state_start "Creating phpenv executable"
    phpenv_script "$install_path" > "$install_path/bin/phpenv" || result=1
    chmod +x "$install_path/bin/phpenv" || result=1
    out_state_done $result
}

update_phpenv()
{
    local install_path="$1"
    local working_path=$(pwd)

    out_state_start "Updating phpenv with $PHPENV_REMOTE_RBENV"
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

    out_state_start "Updating plugin $plugin with $remote"
    cd "$install_path"
    git pull origin master > /dev/null 2>&1
    out_state_done $?
    cd "$working_path"
}

get_phpenv()
{
    local install_path="$1"

    out_state_start "Cloning phpenv with $PHPENV_REMOTE_RBENV"
    git clone "$PHPENV_REMOTE_RBENV" "$install_path" > /dev/null 2>&1
    out_state_done $?
}

get_plugin()
{
    local remote="$2"
    local plugin="$3"
    local install_path="$1/plugins/$plugin"
    local working_path=$(pwd)

    out_state_start "Cloning plugin $plugin with $remote"
    git clone "$remote" "$install_path" > /dev/null 2>&1
    out_state_done $?
    cd "$working_path"
}

do_substitutions()
{
    local install_path="$1"
    local working_path=$(pwd)
    local result=0

    out_state_start "Performing ruby->php file substitutions"
    sed -i -e 's/rbenv/phpenv/g' "$install_path"/completions/* || result=1
    sed -i -e 's/\(^\|[^/]\)rbenv/\1phpenv/g' "$install_path"/libexec/* || result=1
    sed -i -s 's/\.ruby-version/.php-version/g' "$install_path"/libexec/* || result=1
    sed -i -e 's/rbenv/phpenv/g' "$install_path"/libexec/* || result=1
    sed -i -e 's/RBENV/PHPENV/g' "$install_path"/libexec/* || result=1
    sed -i -s 's/Ruby/PHP/g' "$install_path"/libexec/* || result=1
    sed -i -s 's/RUBY/PHP/g' "$install_path"/libexec/* || result=1
    sed -i -s 's/ruby/php/g' "$install_path"/libexec/* || result=1
    out_state_done $result

    result=0
    out_state_start "Renaming internal executables"
    cd "${PHPENV_ROOT}" || result=1
    for f in `ls ${PHPENV_ROOT}/libexec/`; do
        mv "${PHPENV_ROOT}/libexec/$f" "${PHPENV_ROOT}/libexec/phpenv${f:5}" || result=1
    done
    out_state_done $result

    cd "$working_path"
}

main()
{
    local use_plugins=true
    local get_osdeps=false

    if [ -z "$PHPENV_ROOT" ]; then
        PHPENV_ROOT="$HOME/.phpenv"
    fi

    out_title "PHPENV Installer"
    out_line
    out_line "Using path $PHPENV_INSTALLER_REALPATH"

    out_prompt "Use php-build and php-conf plug-ins" $use_plugins
    if [ $? -eq 0 ]; then
        use_plugins=true
    else
        use_plugins=false
    fi

    out_prompt "Install system build dependencies" $get_osdeps
    if [ $? -eq 0 ]; then
        get_osdeps=true
    else
        get_osdeps=false
    fi

    if [ -d $PHPENV_ROOT ]; then
        update_phpenv "$PHPENV_ROOT"
        if [ "$use_plugins" == "true" ]; then
            update_plugin "$PHPENV_ROOT" "$PHPENV_REMOTE_PHPBLD" "php-build"
            update_plugin "$PHPENV_ROOT" "$PHPENV_REMOTE_PHPCFG" "php-conf"
        fi
    else
        get_phpenv "$PHPENV_ROOT"
        if [ "$use_plugins" == "true" ]; then
            get_plugin "$PHPENV_ROOT" "$PHPENV_REMOTE_PHPBLD" "php-build"
            get_plugin "$PHPENV_ROOT" "$PHPENV_REMOTE_PHPCFG" "php-conf"
        fi
    fi

    do_substitutions  "$PHPENV_ROOT"
    create_phpenv_bin "$PHPENV_ROOT"

    if [ "$get_osdeps" == "true" ]; then
        get_build_deps
    fi

    out_instructions
    out_instructions " # Add to $HOME/.bashrc to enable phpenv"
    out_instructions
    out_instructions " export PATH=\"${PHPENV_ROOT}/bin:"'$PATH"'
    out_instructions ' eval "$(phpenv init -)"'
    out_instructions
}

deps()
{
    local working_path="$(pwd)"

    cd "$PHPENV_INSTALLER_REALPATH"
    git submodule update --init > /dev/null 2>&1
    cd "$working_path"

    if ! [ -f "$PHPENV_INSTALLER_REALPATH/../lib/bright/bright.bash" ]; then
        echo "Required dependency does not exist: \"$PHPENV_INSTALLER_REALPATH/../lib/bright/bright.bash\""
        exit 1
    fi
}

deps && source "$PHPENV_INSTALLER_REALPATH/../lib/bright/bright.bash" && main $@

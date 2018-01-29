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

readonly PHPENV_REMOTE_PHPINST="https://github.com/src-run/phpenv.git"

PHPENV_INSTALLER_WORKPATH="${1:-/tmp}"

out_error()
{
    echo "[ERROR] ${1:-An unknown error occured!}"
    exit ${2:-255}
}

rand()
{
    local min=10000
    local max=99999
    local num=0

    while [[ ${num} -lt ${min} ]] || [[ ${num} -gt ${max} ]]; do
        num=${RANDOM}
    done

    echo ${num}
}

temporary_path()
{
    echo "${PHPENV_INSTALLER_WORKPATH}/phpenv-installer-$(rand)$(rand)"
}

main()
{
    local temporary_path="$(temporary_path)"
    local installer_file="/bin/phpenv-installer.bash"

    mkdir -p "${temporary_path}" || \
        out_error "Unable to create temporary work path ${temporary_path} "\
                  "(perhaps you should explicitly set \$PHPENV_INSTALLER_WORKPATH)"

    git clone --quiet --recurse-submodules "${PHPENV_REMOTE_PHPINST}" "${temporary_path}" || \
        out_error "Unable to clone ${PHPENV_REMOTE_PHPINST} int ${temporary_path}"

    ${temporary_path}${installer_file} || \
        out_error "Unable to run installed at ${temporary_path}${installer_file}"

    rm -fr "${temporary_path}" || \
        out_error "Unable to remove temporary work path ${temporary_path}"
}

main $@

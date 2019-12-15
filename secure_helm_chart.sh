#!/bin/bash

###################################################################################################
######################################### Chart Integrity #########################################
###################################################################################################

function __check_gpg_status {

    # check gpg installation
    gpg_version=$(gpg --version)

    gpg_status=$?
    if [ $gpg_status -ne 0 ]; then
        echo "GnuPG is not installed. Installing it..."
        sudo apt install gpg
    fi
}

function __generate_gpg_keypair {

    __check_gpg_status

    gpg_version=$(gpg --version | head -n 1 | cut -d' ' -f3)

    if [ $gpg_version_number -lt "2.1.17" ]; then
        gpg --full-generate-key
    else
        gpg --default-new-key-algo rsa4096 --gen-key
    fi
    # gpg --export-secret-keys > ~/.gnupg/secring.gpg
}

function __generate_keybase_credentials {

    # check keybase installation
    keybase_version=$(keybase --version)

    # check keybase account
    if []; then
        keybase login
    else
        keybase signup
    fi

    keybase pgp gen
    
    # check gnupg installation
    __check_gpg_status

    keybase pgp export -s > secring.gpg
    keybase pgp export -s \
        | gpg --import \
        && gpg --export-secret-keys \
        --outfile secring.gpg
}

function __keybase_verify_charts {

    keybase follow $1
    keybase pgp pull
    #is this supposed to work without the prov files?
}

function secure_chart_packaging {

    # $1 = chart directory
    # $2 = gpg or keybase
    # $3 = path to secring.gpg
    # $4 = key phrase

    if []; then
        # use an existing keypair

    elif []; then
        __generate_pgp_keypair
        key_phrase=$4

    elif []; then
        __generate_keybase_credentials
        key_phrase=$( head $3 -n 1 | cut -d' ' -f1 )
    fi

    # helm package ?
    helm package \
        --sign \
        --key $key_phrase \
        --keyring $3 \
        $1

    # check if provenance file has been generated
    secure_verify_charts $1
}

function secure_verify_charts {

    # https://github.com/helm/helm/blob/master/docs/provenance.md
    if []; then
        __keybase_verify_charts $1
    fi

    helm verify $1/../$1*.tgz
}
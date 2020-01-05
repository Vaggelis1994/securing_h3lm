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

        # TODO: install gpg with the default 
        # package manager based on the OS

        sudo apt install gpg
        # brew install gpg
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
    
    # TODO: check if this line is needed: 
    # gpg --export-secret-keys > ~/.gnupg/secring.gpg
}

function __check_keybase_status {

    keybase_version=$(keybase --version)

    keybase_version=$?
    if [ $keybase_version -ne 0 ]; then 
        echo "Keybase is not installed.
              It is recommended to follow process manually for its installation."

        # TODO: try to install it automatically based on the OS   
        # MacOS
        # curl --remote-name https://prerelease.keybase.io/Keybase.dmg
        # sudo hdiutil attach Keybase.dmg
        # copy files automatically
        # keybase_version=$(keybase --version)
        # while keybase has not been installed  
        # sudo hdiutil detach /Volumes/Keybase\ App/
}

function __generate_keybase_credentials {

    # check keybase installation
    __check_keybase_status

    # check keybase account
    logged=$(keybase account email list)

    # TODO: review error return codes and
    # logged session outputs
    
    if [ $logged -ne 2 ]; then 
        keybase login
    elif [ $logged -eq 2 ]; then
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

    '''

    # $1 - user
    
    '''

    keybase follow $1
    keybase pgp pull
    
    # TODO: is this supposed to work without the prov files (?)
}

function secure_chart_packaging {

    '''
    
    # $1 - chart directory
    # $2 - gpg or keybase
    # $3 - path to secring.gpg
    # $4 - key phrase
    
    '''

    while [[ $# -gt 0 ]] do
        key="$1"

        case $key in 
            -d|--directory)
            directory="$2"
            shift
            shift
            ;;
            -m|--mode)
            mode="$2"
            shift
            shift
            ;;
            -s|--secring)
            secring="$2"
            shift
            shift
            ;;
            -k|--keyphrase)
            keyphrase="$2"
            shift
            shift
            ;;
            *)
            shift
            ;;
        esac
    done
        
    if [ -f secring ]; then 
        continue;
        # use an existing keypair

    elif [ $mode = "gpg" ]; then
        __generate_pgp_keypair

    elif [ $mode = "keybase" ]; then
        __generate_keybase_credentials
        keyphrase=$(head $secring -n 1 | cut -d' ' -f1 )
    fi

    helm package \
        --sign \
        --key $keyphrase \
        --keyring $secring \
        $directory

    # check if provenance file has been generated
    secure_verify_charts $directory
}

function secure_verify_charts {

    '''
    
    Source: http://helm.sh/docs/topics/provenance/
    
    # $1 - chart directory
    # $2 - mode
    
    '''
    
    while [[ $# -gt 0 ]] do
        key="$1"

        case $key in 
            -d|--directory)
            directory="$2"
            shift
            shift
            ;;
            -m|--mode)
            mode="$2"
            shift
            shift
            ;;
            -u|--user)
            user="$2"
            shift
            shift
            ;;
            *)
            shift
            ;;
        esac
    done 


    if [ $mode = "keybase" ]; then
        __keybase_verify_charts $directory
    fi

    helm verify $directory/../$directory*.tgz
}
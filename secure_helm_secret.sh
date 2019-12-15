#!/bin/bash

###################################################################################################
########################################### Helm Secret ###########################################
###################################################################################################

function secure_helm_secrets_install {

    #check helm status
    #check url

    # Install the plugin
    helm plugin install https://github.com/futuresimple/helm-secrets

    # Check status

    # Generate output usage
    helm secrets help

    # Visit the documentation for more info
    echo "Visit: https://github.com/futuresimple/helm-secrets for more information on usage."
    #wrapper?
}

function secure_helm_secrets_encrypt {

    #check helm status
    #check helm secrets status

    if [ $# -ne 1 ]; then
    fi

}

function secure_helm_secrets_decrypt {

    if [ $# -ne 1 ]; then
    fi
}

function secure_helm_secrets_view {

    if [ $# -ne 1 ]; then
    fi
}

function secure_helm_secrets_clean {

    if [ $# -ne 1 ]; then
    fi

    helm secrets clean $1
}

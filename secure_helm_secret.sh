#!/bin/bash

###################################################################################################
########################################### Helm Secret ###########################################
###################################################################################################

. ./secure_helm_install.sh 

function secure_helm_secrets_install {

    # check helm status
    __safe_helm_installation

    # check url status
    url_status=$(curl -s --head https://github.com/futuresimple/helm-secrets | head -n 1 | grep "200")
    if [ $url_status = "" ]; then
    	echo "URL: https://github.com/futuresimple/helm-secrets seems to be broken!"
    fi

    # Install the plugin
    helm plugin install https://github.com/futuresimple/helm-secrets

    # Check status

    # Generate output usage
    helm secrets help

    # Visit the documentation for more info
    echo "Visit: https://github.com/futuresimple/helm-secrets for more information on usage."
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

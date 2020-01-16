#!/bin/bash

###################################################################################################
########################################### Helm Secret ###########################################
###################################################################################################

. ./secure_helm_install.sh 

function __safe_secrets_installation {

}

function secure_helm_secrets_install {

    # check helm status
    __safe_helm_installation

    # check url status
    url_status=$(curl -s --head https://github.com/futuresimple/helm-secrets | head -n 1 | grep "200")
    if [ $url_status = "" ]; then
    	echo "URL: https://github.com/futuresimple/helm-secrets seems to be broken!"
    fi

    # TODO: check status of HELM_HOME variable

    # if not existing, export it
    mkdir /tmp/randomHelmDirectory
    export HELM_HOME=/tmp/randomHelmDirectory

    echo $HELM_HOME
    mkdir $HELM_HOME/plugins

    # Install the plugin
    helm plugin install https://github.com/futuresimple/helm-secrets

    # Check status
    secrets_status=$?    
    if [ $secrets_status -ne 0 ]; then
        echo "There was an issue with the installation. Please try to follow the instructions on the website."
    fi

    # TODO: Check the redirection logic

    # Generate output usage
    helm secrets help 2>&1

    # Visit the documentation for more info
    echo "Visit: https://github.com/futuresimple/helm-secrets for more information on usage."
}

function secure_helm_secrets_encrypt {

    '''

    # $1 - file to be encrypted
    
    '''

    # check helm status
    __safe_helm_installation

    # check helm secrets status
    __safe_secrets_installation

    if [ $# -ne 1 ]; then
        echo "Please provide exactly one .yaml file as an argument to be encrypted."
    fi

    helm secrets enc $1

}

function secure_helm_secrets_decrypt {

    '''

    # $1 - file to be decrypted
    
    '''

    # check helm status
    __safe_helm_installation

    # check helm secrets status
    __safe_secrets_installation

    if [ $# -ne 1 ]; then
        echo "Please provide exactly one .yaml file as an argument to be decrypted."
    fi

    helm secrets swc $1

}

function secure_helm_secrets_view {
    
    '''

    # $1 - file to be viewed-only
    
    '''

    # check helm status 
    __safe_helm_installation

    # check helm secrets status
    __safe_secrets_installation

    if [ $# -ne 1 ]; then
        echo "Please provide exactly one .yaml file as an argument to be viewed."
    fi

    helm secrets view $1

}

function secure_helm_secretes_edit {
    
    '''

    # $1 - file to be edited and encrypted
    
    '''

    # check helm status 
    __safe_helm_installation

    # check helm secrets status
    __safe_secrets_installation

    if [ $# -ne 1 ]; then
        echo "Please provide exactly one .yaml file as an argument to be edited."
    fi

    helm secrets edit $1

}


function secure_helm_secrets_clean {

    '''

    # $1 - directory to be cleared
    
    '''

    # check helm status 
    __safe_helm_installation

    # check helm secrets status
    __safe_secrets_installation

    if [ $# -ne 1 ]; then
        echo "Please provide exactly one directory as an argument to be cleared."
    fi

    helm secrets clean $1
}

function secure_secrets_generate_aliases {

    alias secure_helm_secrets_install="helm secrets install"
    alias secure_helm_secrets_template="helm secrets template"
    alias secure_helm_secrets_upgrade="helm secrets upgrade"
    alias secure_helm_secrets_lint="helm secrets lint"
    
    # TODO: helm install plugin diff
    # alias secure_helm_secrets_diff="helm secrets diff"        

}

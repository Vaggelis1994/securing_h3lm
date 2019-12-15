#!/bin/bash

###################################################################################################
####################################### Secure Installation #######################################
###################################################################################################

function __install_helm {
    # Install Helm binary using the latest version script for its repo

    echo "Helm is not installed. Installing it..."
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
}

function __safe_helm_installation {
    # Check helm binary installation status
    set +e
    which helm
    helm_status=$?
    set -e

    # When error code is different to 0, helm is not installed
    if [ $helm_status -ne 0 ]; then
        __install_helm
    fi
}

function __remove_existed_tiller {
    # TODO: check is existing certificates can be used
    
    # Check TLS usage status, in case the certificates under HELM_HOME can be used
    set +e
    helm version --tls
    helm_status=$?
    set -e

    # Helm has successfully deployed TLS 
    if [ $helm_status -eq 0 ]; then
        return;

    # When error code is different to zero, there is an issue with TLS.
    # Therefore, we need to re-generate the TLS certificates
    set +e
    tiller_exist=$(kubectl get pods --namespace kube-system \
        | awk '{print $1}' \
        | grep -c "^tiller-deploy")
    set -e

    # Delete the tiller instance if it exists, as the certificates
    # need to be issued from scratch
    if [ $tiller_exist -ne 0 ]; then
        helm reset --force
    fi
}

function __openssl_ca_generation {
    # Generate the CA to issue the certificates
    echo "Generating the CA to issue the certificates..."
    openssl genrsa \
        -out ca.key.pem 4096
    openssl req \
        -key ca.key.pem \
        -new \
        -x509 \
        -days 7300 \
        -sha256 \
        -out ca.cert.pem \
        -extensions v3_ca \
        -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com"
}

function __openssl_cert_generation {
    # Generate the certificates for the $1 component
    # $1 -> the component for which the certificates will be generated
    if [ $# -ne 1 ]; then
        echo "Please specify the entity for which the TLS certificates will 
              be deployed"
    fi

    echo "Generating the certificates for the $1 end..."
    openssl genrsa \
        -out $1.key.pem 4096
    openssl req \
        -key $1.key.pem \
        -new \
        -sha256 \
        -out $1.csr.pem \
        -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com"
    openssl x509 -req \
        -CA ca.cert.pem \
        -CAkey ca.key.pem \
        -CAcreateserial \
        -in $1.csr.pem \
        -out $1.cert.pem \
        -days 365 \
        -passin pass:
}

function __store_certificates {

    # Set the directory of helm home
    helm_home=$(helm home)

    # Copy the certificates under the HELM_HOME
    cp ca.cert.pem $helm_home/ca.pem
    cp helm.cert.pem $helm_home/cert.pem
    cp helm.key.pem $helm_home/key.pem

    # Backup all the certificate files
    mkdir -p $helm_home/.certificates
    mv ca.cert.pem \
        ca.key.pem \
        ca.srl \
        helm.key.pem \
        helm.csr.pem \
        helm.cert.pem \
        tiller.key.pem \
        tiller.csr.pem \
        tiller.cert.pem \
        $helm_home/.certificates
}

function secure_helm_install {

    __safe_helm_installation

    __remove_existed_tiller

    # Generate the certificates with the related function calls
    __openssl_ca_generation
    __openssl_cert_generation "helm"
    __openssl_cert_generation "tiller"

    __store_certificates
}

function secure_helm_init {

    #$1 = accountname
    # --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}'
    # will make sure that release info is a secret

    if [ $# -ne 1 ]; then
        echo "Please specify service account name. \
            No service account name was specified."
    fi

    # Check if service account name exists

    # Check if files exist
    if [ ! -f helm.cert.pem ]; then
        echo "File helm.cert.pem was not found!"
    fi

    if [ ! -f helm.key.pem ]; then
        echo "File helm.key.pem was not found!"
    fi

    if [ ! -f ca.cert.pem ]; then
        echo "File ca.cert.pem was not found!"
    fi

    # Install it in other namespace

    # Securely initialize Helm and Tiller
    helm init \
    --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' \
    --tiller-tls \
    --tiller-tls-verify \
    --tiller-tls-cert=helm.cert.pem \
    --tiller-tls-key=helm.key.pem \
    --tls-ca-cert=ca.cert.pem \
    --service-account=$1 \
    --tiller-namespace=$2 \
    --force-upgrade
}

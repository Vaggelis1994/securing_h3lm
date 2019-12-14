# ToDo: code standards
# ToDo: function to replace echo, rm, mv etc(?)
# ToDo: function to log information
# ToDo: wget or similar to URLs before execute
# ToDo: install or upgrade Helm
# ToDo: check number of arguments
# ToDo: Note: when TLS Helm-Tiller, k8s does not have access to the messages between them
# ToDo: Update static code analysis OR find another way if Sonarqube/Coverity does not support it
# ToDo: default and overriden values
# ToDo: avoid direct call of specific functions
# ToDo: openssl keys should prompt for passwords
# ToDo: sleep??

###################################################################################################
####################################### Secure Installation #######################################
###################################################################################################

# HELM_HOME
# HELM_HOST
# HELM_NO_PLUGINS
# TILLER_NAMESPACE
# KUBECONFIG

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

    #encrypt files
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

###################################################################################################
######################################## Role-based access ########################################
###################################################################################################

function secure_deploy_tiller_namespace {

    # $1 = namespace
    # $2 = service_account_name
    # $3 = service_account_namespace

    __create_tiller_namespace \
        $namespace \
        $service_account_name \
        $service_account_namespace
}

function secure_deploy_cluster_admin {

    namespace=kube-system

    clusterrole_name=cluster-admin

    clusterrolebinding_name=tiller-binding

    service_account_name=tiller
    service_account_namespace=$namespace

    __deploy_service_account \
        $service_account_name \
        $service_account_namespace

    __deploy_clusterrolebinding \
        $clusterrolebinding_name \
        $service_account_name \
        $service_account_namespace \
        $clusterrole_name
}

function secure_deploy_tiller_admin {
    # Deploy Tiller in a namespace, restricted to deploying resources only in that namespace

    namespace=tiller-world

    role_name=tiller-manager
    role_namespace=$namespace

    rolebinding_name=tiller-binding
    rolebinding_namespace=$namespace

    service_account_name=tiller
    service_account_namespace=$namespace

    rules='
        rules:
        - apiGroups: ["", "batch", "extensions", "apps"]
          resources: ["*"]
          verbs: ["*"]
    '

    __deploy_role \
        $role_name \
        $role_namespace \
        $rules

    __deploy_rolebinding \
        $rolebinding_name \
        $rolebinding_namespace \
        $service_account_name \
        $service_account_namespace \
        $role_name
}

function secure_deploy_tiller_manager {
    # Deploy Tiller in a namespace, restricted to deploying resources in another namespace

    namespace=myorg-system

    role_name=tiller-manager
    role_namespace=myorg-users

    rolebinding_name=tiller-binding
    rolebinding_namespace=$role_namespace

    service_account_name=tiller
    service_account_namespace=$namespace

    rules='
        rules:
        - apiGroups: ["", "batch", "extensions", "apps"]
          resources: ["*"]
          verbs: ["*"]
    '

    __create_tiller_namespace \
        $namespace \
        $service_account_name \
        $service_account_namespace

    __deploy_role \
        $role_name \
        $role_namespace \
        $rules

    __deploy_rolebinding \
        $rolebinding_name \
        $rolebinding_namespace \
        $service_account_name \
        $service_account_namespace \
        $role_name

    role_namespace=$namespace
    rolebinding_namespace=$namespace
    rules='
        rules:
        - apiGroups: ["", "extensions", "apps"]
          resources: ["configmaps"]
          verbs: ["*"]
    '

    __deploy_role \
        $role_name \
        $role_namespace \
        $rules

    __deploy_rolebinding \
        $rolebinding_name \
        $rolebinding_namespace \
        $service_account_name \
        $service_account_namespace \
        $role_name
}

function secure_deploy_tiller_user {
    # Deploy Helm in a namespace, talking to Tiller in another namespace

    service_account_name=helm
    service_account_namespace=helm-world

    namespace=tiller-world

    role_name=tiller-user
    role_namespace=$namespace

    rolebinding_name=tiller-user-binding
    rolebinding_namespace=$namespace

    rules='
        rules:
        - apiGroups: [""]
          resources: ["pods/portforward"]
          verbs: ["create"]
        - apiGroups: [""]
          resources: ["pods"]
          verbs: ["list"]"
    '

    __deploy_service_account \
        $service_account_name \
        $service_account_namespace

    __deploy_role \
        $role_name \
        $role_namespace \
        $rules

    __deploy_rolebinding \
        $rolebinding_name \
        $rolebinding_namespace \
        $service_account_name \
        $service_account_namespace \
        $role_name
}

function __create_tiller_namespace {

    # $1 = namespace
    # $2 = service_account_name
    # $3 = service_account_namespace

    kubectl create namespace $1
    sleep 5
    kubectl create serviceaccount $2 \
        --namespace $3
    sleep 5
}

function __deploy_service_account {

    # $1 = service_account_name
    # $2 = service_account_namespace

    cp service-account-template service-account.yaml
    sed -i 's/_service_account_name/$1/g' service-account.yaml
    sed -i 's/_service_account_namespace/$2/g' service-account.yaml
    kubectl create -f service-account.yaml
    sleep 5
    rm service-account.yaml
}

function __deploy_role {

    # $1 = role_name
    # $2 = role_namespace
    # $3 = rules

    cp role-template role.yaml
    sed -i 's/_role_name/$1/g' role.yaml
    sed -i 's/_role_namespace/$2/g' role.yaml
    sed -i 's/_rules:/$3/g' role.yaml
    kubectl create -f role.yaml
    sleep 5
    rm role.yaml
}

function __deploy_rolebinding {

    # $1 = rolebinding_name
    # $2 = rolebinding_namespace
    # $3 = service_account_name
    # $4 = service_account_namespace
    # $5 = role_name

    cp rolebinding-template rolebinding.yaml
    sed -i 's/_rolebinding_name/$1/g' rolebinding.yaml
    sed -i 's/_rolebinding_namespace/$2/g' rolebinding.yaml
    sed -i 's/_service_account_name/$3/g' rolebinding.yaml
    sed -i 's/_service_account_namespace/$4/g' rolebinding.yaml
    sed -i 's/_role_name/$5/g' rolebinding.yaml
    kubectl create -f rolebinding.yaml
    sleep 5
    rm rolebinding.yaml
}

function __deploy_clusterrolebinding {

    # $1 = clusterrolebinding_name
    # $2 = service_account_name
    # $3 = service_account_namespace
    # $4 = clusterrole_name

    cp clusterrolebinding-template clusterrolebinding.yaml
    sed -i 's/_clusterrolebinding_name/$1/g' clusterrolebinding.yaml
    sed -i 's/_service_account_name/$2/g' clusterrolebinding.yaml
    sed -i 's/_service_account_namespace/$3/g' clusterrolebinding.yaml
    sed -i 's/_clusterrole_name/$4/g' clusterrolebinding.yaml
    kubectl create -f clusterrolebinding.yaml
    sleep 5
    rm clusterrolebinding.yaml
}

###################################################################################################
######################################### Chart integrity #########################################
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

###################################################################################################
############################################## Other ##############################################
###################################################################################################

function secure_roll_deployments_automatically {

    #check status
    #find deployments $1
    #grep -nrw $1 -e "sha256sum"
    #if not deployed -> sed or input line checksum/config

    grep "kind: Deployment"
    grep "kind: ConfigMap"
    grep "kind: Secrets"

    secrets=$(grep "checksum/secrets" | wc -l)
    secrets_checksum=$(grep "checksum/secrets" | grep "sha256sum" | wc -l)
    if [ $secrets_used ] && [ $secrets -ne $secrets_checksum ]; then
        sed
    fi

    configs=$(grep "checksum/config" | wc -l)
    configs_checksum=$(grep "checksum/config" | grep "sha256sum" | wc -l) 
    if [ $configs_used ] && [ $configs -ne $configs_checksum ]; then
        sed
    fi
}

function secure_image_pull_secrets {

    # https://github.com/helm/helm/blob/master/docs/charts_tips_and_tricks.md#creating-image-pull-secrets
    touch "_imagePullSecrets.yaml"

    echo "{{- define \"imagePullSecret\" }}" > "_imagePullSecrets.yaml"
    echo "{{- printf \"{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}\" .Values.imageCredentials.registry \
        (printf \"%s:%s\" .Values.imageCredentials.username .Values.imageCredentials.password \
        | b64enc) | b64enc }}" >> "_imagePullSecrets.yaml"
    echo "{{- end }}" >> "_imagePullSecrets.yaml"
}

function secure_generate_aliases {

    alias secure_helm_delete="helm delete --tls"
    alias secure_helm_dependency_build="helm dependency build --verify"
    alias secure_helm_dependency_update="helm dependency update --verify"
    alias secure_helm_fetch="helm fetch --verify --key-file"
    alias secure_helm_get="helm get --tls"
    alias secure_helm_history="helm history --tls"
    alias secure_helm_inspect="helm inspect --verify"
    alias secure_helm_inspect_chart="helm inspect chart --verify --key-file"
    alias secure_helm_inspect_readme="helm inspect readme --verify --key-file"
    alias secure_helm_inspect_readme="helm inspect values --verify --key-file"
    alias secure_helm_install="helm install --verify --tls --key-file"
    alias secure_helm_list="helm list --tls"
    alias secure_helm_package="helm package --sign"
    alias secure_helm_repo_add="helm repo add --no-update --key-file"
    alias secure_helm_reset="helm reset --tls"
    alias secure_helm_rollback="helm rollback --tls --recreate-pods"
    alias secure_helm_secret="helm secrets"
    alias secure_helm_status="helm status --tls"
    alias secure_helm_test="helm test --tls"
    alias secure_helm_upgrade="helm upgrade --recreate-pods --tls --verify --key-file"
    alias secure_helm_verify="helm verify"
    alias secure_helm_version="helm version --tls"
}

###################################################################################################
########################################### Secure Helm ###########################################
###################################################################################################

function secure_helm {

    # service_account_name 
    # namespace

    secure_helm_install
    secure_helm_secrets_install

    secure_deploy_cluster_admin \
        $namespace

    # Create RBAC users
    while []; do
        echo ""
        secure_deploy_tiller_namespace \
            $namespace \
            $service_account_name \
            $service_account_namespace
        if []; then
            secure_deploy_tiller_admin \
                $namespace \
                $role_name \
                $rolebinding_name \
                $service_account_name
        elif []; then
            secure_deploy_tiller_manager \
                $namespace \
                $role_namespace \
                $role_name \
                $rolebinding_name \
                $service_account_name
        elif []; then
            secure_deploy_tiller_user \
                $namespace \
                $service_account_namespace \
                $role_name \
                $rolebinding_name \
                $service_account_name
        else
            echo "Unknown Option."
        fi
    done

    # 
    secure_helm_init \
        $service_account_name \
        $namespace

    secure_verify_charts
    secure_generate_provenance_files

    secure_roll_deployments_automatically
    secure_image_pull_secrets
    secure_generate_aliases
}
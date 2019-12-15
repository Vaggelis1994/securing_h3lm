#!/bin/bash

##################################################################################################
############################################## Misc ##############################################
##################################################################################################

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
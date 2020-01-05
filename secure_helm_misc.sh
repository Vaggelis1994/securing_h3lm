#!/bin/bash

##################################################################################################
############################################## Misc ##############################################
##################################################################################################

function secure_roll_deployments_automatically {

    '''
        Often times _ConfigMaps_ or _Secrets_ are injected as configuration files in containers or 
        there are other external dependencies changes that require rolling pods. Depending on 
        the application a restart may be required should those be updated with a subsequent 
        `helm upgrade`, but if the deployment spec itself didn’t change the application keeps 
        running with the old configuration resulting in an inconsistent deployment.

    '''

    # TODO: check status
    # TODO: retrieve file
    # TODO: kubectl 

    file=""

    # TODO: use this as counter 
    # deployment=$(grep "Deployment:" $file | wc -l)

    configs=$(grep "checksum/config" $file | wc -l)
    configs_checksum=$(grep "checksum/config" $file | grep "sha256sum" | wc -l) 

    # check if the sha256sum is already used for all of the checksum/config entries
    if [ $configs_used ] && [ $configs -ne $configs_checksum ]; then
        line=$(grep "checksum/config" $file | cut -d '}' -f 1)
        checksum_line=$(echo $line" | sha256sum }}") 
        sed -i 's/$line/$checksum_line/g' $file
    fi

    # inject rollme entity to always roll the deployment
    rollme=$(grep "rollme" $file | wc -l)
    if [ $rollme -ne 0 ]; then
        sed -i 's/annotations:/annotations:\n
                rollme: {{ randAlphaNum 5 | quote }}/g'
    fi
}

function secure_image_pull_secrets {

    '''
    
        Source: https://helm.sh/docs/howto/charts_tips_and_tricks/#creating-image-pull-secrets
    
    '''

    # 1. Assume that the credentials are defined in the "values.yaml" file.

    # 2. Definition of helper template 

    touch "_imagePullSecrets.yaml"

    echo "{{- define \"imagePullSecret\" }}" > "_imagePullSecrets.yaml"
    echo "{{- printf \"{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}\" .Values.imageCredentials.registry \
        (printf \"%s:%s\" .Values.imageCredentials.username .Values.imageCredentials.password \
        | b64enc) | b64enc }}" >> "_imagePullSecrets.yaml"
    echo "{{- end }}" >> "_imagePullSecrets.yaml"

    # 3. Using the helper template in a larger template to create the Secret manifest

    touch "secret_manifest.yaml"

    echo "apiVersion: v1\
          kind: Secret\
          metadata: \
            name: myregistrykey \
            type: kubernetes.io/dockerconfigjson \
        data:
            .dockerconfigjson: {{ template \"imagePullSecret\" . }}" > secret_manifest.yaml

    # kubectl create -f secret_manifest.yaml
}

function secure_generate_aliases {

    # TODO: To review all the options and their respective secure versions

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

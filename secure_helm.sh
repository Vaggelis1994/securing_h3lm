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

# HELM_HOME
# HELM_HOST
# HELM_NO_PLUGINS
# TILLER_NAMESPACE
# KUBECONFIG

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
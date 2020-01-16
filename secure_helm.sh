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
########################################### Secure Helm ###########################################
###################################################################################################

# Source files
. ./secure_helm_install.sh
. ./secure_helm_secret.sh
. ./secure_helm_rbac.sh
. ./secure_helm_chart.sh
. ./secure_helm_misc.sh

# Export variables
export HELM_HOME=
export HELM_HOST=
export HELM_NO_PLUGINS=
export TILLER_NAMESPACE=
export KUBECONFIG=

# Optional helm auto-completion
shell=$(which $SHELL | cut -d'/' -f3)
helm completion $shell > .completion
. ./.completion
rm -f .completion

function secure_helm {

	# TODO: parse input

    # service_account_name 
    # namespace

    secure_helm_install
    secure_helm_secrets_install

    # TODO: Create RBAC users menu
    # while []; do
    # done

    # Initialize Helm
    secure_helm_init \
        $service_account_name \
        $namespace

    # TODO: Review basic execution
    secure_verify_charts
    secure_generate_provenance_files
    secure_roll_deployments_automatically
    secure_image_pull_secrets
    secure_generate_aliases

}

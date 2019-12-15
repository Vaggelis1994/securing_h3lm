#!/bin/bash

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

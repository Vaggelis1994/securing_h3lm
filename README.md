# securing_h3lm
securing_h3lm is a set of functions for leveraging the security capabilities and features of Helm 

In a nutshell:

By default, installing and using Helm is not guaranting security. While it is getting more and more popular as part of the projects using Kubernetes as well as the CI/CD pipeline, the set of scripts assures the following:

* The latest helm binary installation.
* The latest helm-secrets installation, the plugin to manage and store secrets safely.
* Helm and Tiller communication over TLS.
* Integrating automatical rolling of the deployments, when configmaps or secrets change.
* RBAC utilization for the cluster used by Helm.
* Configuring Tiller so that each gRPC endpoint uses a separate TLS certificate.
* Release information being a Kubernetes Secret.
* Tiller installation per user, team, or other organizational entity with the --service-account flag, Roles, and RoleBindings.
* Enforcing verification with the --tiller-tls-verify option for the helm init command and with the --tls flag with other Helm commands.
* Verifying the charts are signed and valid.
* Generation of the provenance files for integrity purposes.
* Generation of a helper template in order to securely create image pull secrets.
* Any other, if any, feature that can contribute to maximizing the security aspect of Helm installation and its components.

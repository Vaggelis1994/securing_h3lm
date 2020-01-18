# securing_h3lm
securing_h3lm consists of a set of functions for maxizing the security aspect of Helm 

**In a nutshell:**
By default, installing and using Helm is not granting any security at all. While it is getting more and more popular as part of the projects using Kubernetes as well as the CI/CD pipeline deployments, the set of scripts assures the following:

* Latest `helm` binary installation.
* Latest `helm-secrets` installation; the plugin to manage and store secrets safely.
* **Helm** and **Tiller** communication over TLS.
* Integrity of **Automatically Rolling Deployments**, when configmaps or secrets change.
* **RBAC** utilization for the cluster used by Helm.
* Configuration of **Tiller** for each **gRPC** endpoint to be using a separate TLS certificate.
* Release information being a **Kubernetes Secret**.
* **Tiller** installation per entity, with the `--service-account`.
* Verification with the `--tiller-tls-verify` and `--tls` flags.
* Verification that the **Charts** being signed and valid.
* Generation of the **provenance** files for integrity purposes.
* Generation of a helper template to securely create **Image Pull Secrets**.

*Important Note*: The deployed function are to be used with **Helm v.2**. A new set will be deployed for **v.3**. In addition, currently, **Tiller** is deprecated. 

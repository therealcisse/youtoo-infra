### Introduction

The project is a list of vital components needed to set up the infrastructure required for our application. Our application itself will be deployed by ArgoCD from another repository but will use these components to provide a microservices architecture.

The application manifests are found at therealcisse/youtoo-manifests.

1. **[Jaeger](https://www.jaegertracing.io/)**: Configures Jaeger, a distributed tracing system used to monitor and troubleshoot microservices-based applications.

2. **[Fluent Bit](https://fluentbit.io/)**: Sets up Fluent Bit for log aggregation, collecting and forwarding logs to a centralized location for easier analysis.

3. **[ArgoCD](https://argo-cd.readthedocs.io/)**: Deploys ArgoCD, a declarative, GitOps-based continuous delivery tool for Kubernetes.

4. **[Prometheus Operator](https://prometheus-operator.dev/)**: Implements Prometheus for monitoring and alerting, handling setup and configuration details.

5. **[OpenTelemetry Collector](https://opentelemetry.io/)**: Sets up OpenTelemetry for tracing and metrics collection, aiding in observability. The collector will be installed as a sidecar to our deployments.

6. **[Seq](https://datalust.co/seq)**: Configures Seq for centralized log management and visualization.

7. **[Cert-Manager](https://cert-manager.io/)**: Manages certificates within the Kubernetes cluster.

8. **[HashiCorp Vault](https://www.vaultproject.io/)**: Handles secret management, ensuring secrets are not stored in the repository.

### How to Install

#### Prerequisites

Ensure the following tools are installed (macOS is used):

1. **[direnv](https://direnv.net/)**: A tool to load and unload environment variables depending on the current directory.

   - Installation: Use your package manager, e.g., `brew install direnv` for macOS.
   - Create a `.env` file for user-defined environment variables. Variables like `TF_VAR_HCP_CLIENT_ID` and `TF_VAR_HCP_CLIENT_SECRET` will be added here.

2. **[Terraform](https://www.terraform.io/)**: For provisioning the infrastructure described in the configuration files.

3. **[Rancher Desktop](https://rancherdesktop.io/)**: To create a local Kubernetes cluster for deployment.

4. **[kubectl](https://kubernetes.io/docs/tasks/tools/)**: A command-line tool for interacting with the Kubernetes cluster.

5. **[krew](https://krew.sigs.k8s.io/)**: The kubectl plugin manager to extend kubectl with various useful plugins.

6. **Additional Tools**:

   - **[netshoot](https://github.com/nicolaka/netshoot)**: A diagnostic tool to help troubleshoot network issues within the cluster.
   - **[kubens](https://github.com/ahmetb/kubectx)**: A plugin that makes it easy to switch between Kubernetes namespaces.
   - **[kubectx](https://github.com/ahmetb/kubectx)**: A tool for switching between Kubernetes contexts.
   - **[k9s](https://k9scli.io/)**: A terminal UI to interact with the Kubernetes cluster and manage resources more intuitively.

#### Installation Steps on Rancher Desktop

1. **Install Prerequisites**:

   - Use the package manager for your OS to install the required tools.

2. **Clone the Repository**:

   - Download or clone the repository containing the Terraform files.

3. **Set Up Rancher Desktop**:

   - Ensure Rancher Desktop is installed and running with a Kubernetes environment configured.

4. **Set Up HashiCorp Vault**:

   - Create an account and a project on [HashiCorp](https://www.hashicorp.com/).
   - Log in to HashiCorp Vault.
   - Provision a service principal, including its client ID and client secret.
   - Add the client ID and secret to the `.env` file as seen in the provided repository, using the following format:

   ```
   TF_VAR_HCP_CLIENT_ID=$HCP_CLIENT_ID
   TF_VAR_HCP_CLIENT_SECRET=$HCP_CLIENT_SECRET
   ```

5. **Apply Terraform Configurations**:

   - Navigate to the folder containing the Terraform files.
   - Initialize Terraform: `terraform init`
   - Plan the infrastructure: `terraform plan`
   - Create a `terraform.tfvars` file to store variable values (this file will not be committed to version control), and then apply the infrastructure changes: `terraform apply`

### Tools Overview

- **kubectl**: The go-to command-line tool for managing Kubernetes clusters. It's used for deploying applications, viewing and managing cluster resources, and troubleshooting.
- **krew**: A plugin manager for kubectl that allows easy installation of third-party tools.
- **netshoot**: An all-in-one troubleshooting and debugging toolkit for Kubernetes clusters.
- **kubens** and **kubectx**: These plugins make namespace and context switching seamless, improving productivity when managing multiple clusters or namespaces.
- **k9s**: A command-line interface for Kubernetes, providing a terminal UI that helps interact with Kubernetes resources in a more intuitive way.

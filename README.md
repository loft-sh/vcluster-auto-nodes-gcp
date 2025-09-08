# vCluster Auto Nodes GCP

**td;dr**: I just need a `vcluster.yaml` to get started:

```yaml
# vcluster.yaml
controlPlane:
  service:
    spec:
     type: LoadBalancer

privateNodes:
  enabled: true
  autoNodes:
    dynamic:
    - name: gcp-cpu-nodes
      provider: gcp-compute
      requirements:
      - property: instance-type
        operator: In
        values: ["e2-medium", "e2-standard-2", "e2-standard-4"]
```

## Overview

Terraform modules for Auto Nodes on GCP to dynamically provision Compute instances for vCluster Private Nodes using Karpenter.

- Dynamic provisioning - Nodes scale up/down based on pod requirements
- Multi-cloud support: Works across public clouds, on-premises, and bare metal
- Cost optimization - Only provision the exact resources needed
- Simplified configuration - Define node requirements in your vcluster.yaml

This quickstart NodeProvider isolates all nodes into separate VPCs by default.

Per virtual cluster, it'll create (see [Environment](./environment/)):

- A VPC
- A public subnet
- A private subnet
- A Cloud NAT for all subnets
- Firewall rules for the worker nodes

Per virtual cluster, it'll create (see [Node](./node/)):

- An Compute instance with the selected `instance-type`, attached to the private Subnet. IMPORTANT: If no default zone is set and `privateNodes.autoNodes[*].requirements` doesn't contain a `zone` property new VMs will be spread across available zones in the specified region.

## Getting started

### Prerequisites

1. Access to a GCP account
2. A host kubernetes cluster, preferrably on GKE to use Workload Identity
3. vCluster Platform running in the host cluster. [Get started](https://www.vcluster.com/docs/platform/install/quick-start-guide)
4. Ensure the [Cloud Resource Manager API](https://cloud.google.com/resource-manager/docs) is enabled in your GCP account
5. (optional) The [vCluster CLI](https://www.vcluster.com/docs/vcluster/#deploy-vcluster)
6. (optional) Authenticate the vCluster CLI `vcluster platform login $YOUR_PLATFORM_HOST`

### Setup

#### Step 1: Configure Node Provider

Define your GCP Node Provider in the vCluster Platform. This provider manages the lifecycle of Compute instances.

In the vCluster Platform UI, navigate to "Infra > Nodes", click on "Create Node Provider" and then use "GCP Compute".
Specify a **Project** in which all resources will be created. You can optionally set a **default region** and **default zone**. This can still be changed on a per virtual cluster basis later on.

#### Step 2: Authenticate the Node Provider

Auto Nodes supports two authentication methods for GCP resources. **Workload Identity is strongly recommended** for production use.

##### Option A: Workload Identity (Recommended)

[Configure GKE Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) to grant the vCluster control plane permissions to manage Compute Instances.
Next, create [an IAM role](./docs/auto_nodes_role.yaml) for your organization

```bash
gcloud iam roles create vClusterPlatformAutoNodes --organization=$ORG_ID --file=./auto_nodes_role.yaml
```

or for your project

```bash
gcloud iam roles create vClusterPlatformAutoNodes --project=$PROJECT_ID --file=./auto_nodes_role.yaml
```

Assign the role you just created to your IAM principal to authenticate the terraform provider.

##### Option B: Manual secrets

If Workload Identity is not available, use a kubernetes secret with static credentials to authenticate against GCP.
You can create this secret from the vCluster Platform UI by choosing "specify credentials inline" in the Quickstart setup, or manually later on:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: gcp-credentials
  namespace: vcluster-platform
  labels:
    terraform.vcluster.com/provider: "gcp-compute" # This has to match your provider name
stringData:
    GOOGLE_CREDENTIALS: |
      { "..." }
EOF
```

This uses a [service account key](https://cloud.google.com/iam/docs/service-account-creds).
Ensure the Service Account has at least the permissions outlined in [the auto nodes role](./docs/auto_nodes_role.yaml).

#### Step 3: Create virtual cluster

This vcluster.yaml file defines a Private Node Virtual Cluster with Auto Nodes enabled. It exposes the control plane through a LoadBalancer on the GKE host cluster. This is required for individual Compute Instances to join the cluster.

```yaml
# vcluster.yaml
controlPlane:
  service:
    spec:
     type: LoadBalancer

privateNodes:
  enabled: true
  autoNodes:
    dynamic:
    - name: gcp-cpu-nodes
      provider: gcp-compute
      requirements:
      - property: instance-type
        operator: In
        values: ["Standard_D2s_v5", "Standard_D4s_v5", "Standard_D8s_v5"]
      limits:
        cpu: "100"
        memory: "200Gi"
```

Create the virtual cluster through the vCluster Platform UI or the vCluster CLI:

 `vcluster platform create vcluster gcp-private-nodes -f ./vcluster.yaml --project default`

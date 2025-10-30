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
  - provider: gcp-compute
    dynamic:
    - name: gcp-cpu-nodes
      nodeTypeSelector:
      - property: instance-type
        operator: In
        values: ["e2-medium", "e2-standard-2", "e2-standard-4"]
```

## Overview

Terraform modules for provisioning **Auto Nodes on GCP**.  
These modules dynamically create Compute Engine instances as vCluster Private Nodes, powered by **Karpenter**.

### Key Features

- **Dynamic provisioning** – Nodes automatically scale up or down based on pod requirements  
- **Multi-cloud support** – Run vCluster nodes across GCP, AWS, Azure, on-premises, or bare metal  
  - CSI configuration in multi-cloud environments requires manual setup.
- **Cost optimization** – Provision only the resources you actually need  
- **Simple configuration** – Define node requirements directly in your `vcluster.yaml`  

By default, this quickstart **NodeProvider** isolates each vCluster into its own VPC.

---

## Resources Created Per Virtual Cluster

### [Infrastructure](./environment/infrastructure)

- A dedicated VPC  
- Public subnets in two zones  
- Private subnets in two zones  
- A Cloud NAT for private subnets  
- Firewall rules for worker nodes  
- A service account for worker nodes  
  - Permissions depend on whether CCM and CSI are enabled  

### [Kubernetes](./environment/kubernetes)

- Cloud Controller Manager for node initialization and automatic LoadBalancer creation  
- GCP Persistent Disk CSI driver with a default storage class  
  - The default storage class does **not** enforce allowed topologies (important in multi-cloud setups). You can provide your own.  

### [Nodes](./node/)

- Compute Engine instances using the selected `machine-type`, attached to private subnets  
  - If no default zone is set and `privateNodes.autoNodes[*].nodeTypeSelector` does not contain a `zone`, nodes may be spread across available zones in the selected region.  

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
  - provider: gcp-compute
    dynamic:
    - name: gcp-cpu-nodes
      nodeTypeSelector:
      - property: instance-type
        operator: In
        values: ["e2-medium", "e2-standard-2", "e2-standard-4"]
      limits:
        cpu: "100"
        memory: "200Gi"
```

Create the virtual cluster through the vCluster Platform UI or the vCluster CLI:

 `vcluster platform create vcluster gcp-private-nodes -f ./vcluster.yaml --project default`

## Advanced configuration

### NodeProvider configuration options

You can configure the **NodeProvider** with the following options:

| Option                        | Default       | Description                                                                                 |
| ----------------------------- | ------------- | ------------------------------------------------------------------------------------------- |
| `vcluster.com/ccm-enabled`    | `true`        | Enables deployment of the Cloud Controller Manager.                                         |
| `vcluster.com/ccm-lb-enabled` | `true`        | Enables the CCM service controller. If disabled, CCM will not create LoadBalancer services. |
| `vcluster.com/csi-enabled`    | `true`        | Enables deployment of the CSI driver with a `<provider>-default-disk` storage class.                 |
| `vcluster.com/vpc-cidr`       | `10.10.0.0/16` | Sets the VPC CIDR range. Useful in multi-cloud scenarios to avoid CIDR conflicts.           |

## Example

```yaml
controlPlane:
  service:
    spec:
     type: LoadBalancer
privateNodes:
  enabled: true
  autoNodes:
  - provider: gcp-compute
    properties:
      vcluster.com/ccm-lb-enabled: "false"
      vcluster.com/csi-enabled: "false"
      vcluster.com/vpc-cidr: "10.20.0.0/16"
    dynamic:
    - name: gcp-cpu-nodes
      nodeTypeSelector:
      - property: instance-type
        operator: In
        values: ["e2-medium", "e2-standard-2", "e2-standard-4"]
```

## Security considerations

> **_NOTE:_** When deploying [Cloud Controller Manager (CCM)](https://kubernetes.io/docs/concepts/architecture/cloud-controller/) and [Container Storage Interface (CSI)](https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/) with Auto Nodes, permissions are granted through user assigned managed identity.
**This means all worker nodes inherit the same permissions as CCM and CSI.**
As a result, **any pod the cluster could potentially access the same cloud permissions**.
Refer to the full [list of permissions](environment/infrastructure/iam.tf) for details.

Cluster administrators should be aware of the following:

- **Shared permissions** – all pods running in a **host network** may gain the same access level as CCM and CSI.  
- **Mitigation** – cluster administrators can disable CCM and CSI deployments.  
  In that case, virtual machines will not be granted additional permissions.  
  However, responsibility for deploying and securely configuring CCM and CSI will then fall to the cluster administrator.  

> **_NOTE:_** Security-sensitive environments should carefully review which permissions are granted to clusters and consider whether CCM/CSI should be disabled and managed manually.

## Limitations

### Hybrid-cloud and multi-cloud

When running a vCluster across multiple providers, some additional configuration is required:

- **CSI drivers** – Install and configure the appropriate CSI driver for GCP cloud provider.  
- **StorageClasses** – Use `allowedTopologies` to restrict provisioning to valid zones/regions.  
- **NodePools** – Add matching zone labels so the scheduler can place pods on nodes with storage in the same zone.  

For details on multi-cloud setup, see the [Deploy](https://www.vcluster.com/docs/vcluster/deploy/worker-nodes/private-nodes/auto-nodes/quick-start-templates#deploy) and [Limits](https://www.vcluster.com/docs/vcluster/deploy/worker-nodes/private-nodes/auto-nodes/quick-start-templates#hybrid-cloud-and-multi-cloud) vCluster documentation.

#### Example: GCP PD Disk StorageClass with zones

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gcp-standard
provisioner: pd.csi.storage.gke.io
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: pd-standard
allowedTopologies:
  - matchLabelExpressions:
      - key: topology.gke.io/zone
        values: ["us-central1-a"]
```

### Region changes

Changing the region of an existing node pool is not supported.
To switch regions, create a new virtual cluster and migrate your workloads.

### Dynamic nodes `Limit`

When editing the limits property of dynamic nodes, any nodes that already exceed the new limit will **not** be removed automatically.
Administrators are responsible for manually scaling down or deleting the excess nodes.
# Scalegrid Platform Engineer Tecnical Assessment

Solution for the challenge proposed by Scalegrid for Platform Engineer position.

## The challenge:

- Create 2 Kubernetes clusters in your preferred cloud platform through IaC (e.g. Terraform).
- Deploy a Redis cluster across the 2 clusters in a High Availability setup through helm charts ONLY.

## The solution proposed:

Create a Kubernetes managed instance in Google Cloud Platform (GKE), provisoned by Terraform, using an open source Helm chart solution for High Availability Redis cluster.

## The Architecture

- 1 GKE Cluster with **3 nodes** in **europe-west1**.
- 3 nodes with 6 vCPUs and 12GB of RAM.
- 3 clusters Redis in HA mode (syncing between then)
- 1 Load balancer (HAproxy) handling the traffic.

## Pre-requisites to build the solution

### Sofware

- A [Google Cloud Platform](http://cloud.google.com) account.
- Google Cloud SDK [(gcloud)](https://cloud.google.com/sdk/docs/install?hl=pt-br).
- [Open Tofu](https://opentofu.org/) or [Terraform](https://www.terraform.io/).
- [Helm](https://helm.sh/).
- Kubernetes Command line tool [(kubectl)](https://kubernetes.io/docs/tasks/tools/#kubectl).

For tests

- [Docker](https://www.docker.com/)

### Google Cloud definitions

To create an environment on Google Cloud follow the link above related to GCP or type the command below and follow the instructions.

```
gcloud init
```

After the definitons where done, the authenticatio is needed to prepare the machine to GCP integration.

```
gcloud auth application-default login
```

Before continuing is mandatory to enable the billing for the project and activating the required APIs.

For the billing part, navigate to the web console and [follow the steps here](https://cloud.google.com/billing/docs/how-to/modify-project#to_view_the_account_linked_to_a_project_do_the_following). For enabling the API's follow the steps below.

```
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
```

> Note: The id of the project must be filled in variables.tf in the follwing section:

```
variable "project_id" {
  description = "The project ID to host the cluster in"
  default     = "<PUT_THE_PROJECT_ID_HERE>"
}
```

## Provisioning the infrastructure

### Initializing the project

For the provisioning of infrastructure we will use Open Tofu with [official Google provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs) and some official modules.

- [network](https://registry.terraform.io/modules/terraform-google-modules/network/google/latest)
- [address](https://registry.terraform.io/modules/terraform-google-modules/address/google/latest)
- [kubernetes-engine](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest/) 
    - [auth](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest/submodules/auth)
    - [private-cluster](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest/submodules/private-cluster)

To initializa the project type `tofu init` inside the root dir of project. This will initiliaze the Open Tofu environment and install all the modules.

### The provisioning - GKE cluster.

After initialize the project type `tofu plan`

OT will perform a dry-run and will prompt you with a detailed summary of what resources are about to create.

If you feel confident that everything looks fine, you can create the cluster with `tofu apply`. It will re-run the plan and then type yes to confirm.

**Note:** At the end of provisioning the OT will print an external I address. This IP address will be used in the definition of install of the Redis Helm chart.

### Getting the GKE credentials.

After the provisioning finished ok, we need to authenticate and get credentials for the K8s cluster, running the following command.

```
gcloud container clusters get-credentials scalegrid-prod --location europe-west1
```

## Provisioning the Redis clusters.

### Creating namespace

Before provisioning the Redis cluster, create a namespace for the segmentation of the project. The config reference could be found in **kubeconfig-prod** file, created by OT after the provisioning.

```
kubectl create namespace scalegrid --kubeconfig=kubeconfig-prod
```

### Installing the Helm chart.

To install the Helm chart first we need to add the repo to local env.

```
helm repo add dandydev https://dandydeveloper.github.io/charts
```

The install require require some attributes to be overridden as described below.

- Set the `haproxy.enabled` to `true` so it will enable the HAproxy to act as a load balanncer for the requests directed to Redis K8s service.
- Set the `haproxy.service.type` to `LoadBalancer`, the default value is `ClusterIP`.
- The value of `haproxy.service.loadBalancerIP` is the output of OT provisioning.

The command shoudl be like this:

```
helm install dandydev/redis-ha --generate-name --set haproxy.enabled=true --set haproxy.service.type=LoadBalancer --set haproxy.service.loadBalancerIP=35.205.233.16
```

**Hack:** The deployment may take some minutes, use the command below shows the status of deployment. When the deployment finishes type ctrl+c to exit the "monitoring command".

```
watch -n 1 kubectl get all --namespace=scalegrid -o wide
```

The final result after the install should be something similar to this:

```
NAMESPACE     NAME                                                        READY   STATUS     RESTARTS   AGE
default       pod/redis-ha-1713387731-haproxy-6bb6fc6796-m84br            1/1     Running    0          23s
default       pod/redis-ha-1713387731-haproxy-6bb6fc6796-xtt2q            1/1     Running    0          23s
default       pod/redis-ha-1713387731-haproxy-6bb6fc6796-xxjk5            1/1     Running    0          23s
default       pod/redis-ha-1713387731-server-0                            3/3     Running    0          23s
default       pod/redis-ha-1713387731-server-1                            3/3     Running    0          23s
default       pod/redis-ha-1713387731-server-2                            3/3     Running    0          23s

NAMESPACE     NAME                                                        READY   STATUS     RESTARTS   AGE
default       service/redis-ha-1713387731              ClusterIP      None            <none>        6379/TCP,26379/TCP   24s
default       service/redis-ha-1713387731-announce-0   ClusterIP      10.30.214.12    <none>        6379/TCP,26379/TCP   24s
default       service/redis-ha-1713387731-announce-1   ClusterIP      10.30.212.196   <none>        6379/TCP,26379/TCP   24s
default       service/redis-ha-1713387731-announce-2   ClusterIP      10.30.40.84     <none>        6379/TCP,26379/TCP   24s
default       service/redis-ha-1713387731-haproxy      LoadBalancer   10.30.77.175   35.205.233.16  6379:31005/TCP       24s

NAMESPACE     NAME                                                        READY   STATUS     RESTARTS   AGE
default       deployment.apps/redis-ha-1713387731-haproxy     3/3     3            3           23s

NAMESPACE     NAME                                                        READY   STATUS     RESTARTS   AGE
default       replicaset.apps/redis-ha-1713387731-haproxy-6bb6fc6796     3         3         3       24s

NAMESPACE     NAME                                                        READY   STATUS     RESTARTS   AGE
default      statefulset.apps/redis-ha-1713387731-server   0/3     24s
```

The solution provisioning a replicaset with count of 3 and the [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) handle the sync between the instances. The default settings from the chat cover the most basic configs for Redis and Sentinel, but there is a lot of settings that may be found in the [chart documentation](https://artifacthub.io/packages/helm/dandydev-charts/redis-ha).

The Redis instances are not accessible by internet, only the load balancer by external IP address.

## Testing scenarios.

### Testing Redis connection

To test the connection to Redis cluster my be done by **redis-cli** command tool.

```
$ redis-cli -h 35.205.233.16 -p 6379       
35.205.233.16:6379> SET mykey "Hello\nWorld"
OK
35.205.233.16:6379> GET mykey 
"Hello\nWorld"
```

Or just send the Redis command thogether withs string connection.

```
$ redis-cli -h 35.205.233.16 -p 6379 GET mykey
"Hello\nWorld"
```

### Testing Redis HA

To test the HA of Redis delete one or more pods of server and then try to connect again to the lb address.

Deleting the pod(s):

```
kubectl -n scalegrid delete pod/redis-ha-1713388259-server-0
```

Then try to connect to Redis cluster.

```
$ redis-cli -h 35.205.233.16 -p 6379 GET mykey
```
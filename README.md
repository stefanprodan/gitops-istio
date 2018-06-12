# GitOps for Istio Canary Deployments

This is a step by step guide on how to set up a GitOps workflow for Istio with Weave Flux. 
GitOps is a way to do Continuous Delivery, it works by using Git as a source of truth for declarative infrastructure 
and workloads. In practice this means using `git push` instead of `kubectl create/apply` or `helm install/upgrade`.

### Install Weave Flux with Helm

Add the Weave Flux chart repo:

```bash
helm repo add weaveworks https://weaveworks.github.io/flux
```

Install Weave Flux and its Helm Operator by specifying your fork URL 
(replace `stefanprodan` with your GitHub username): 

```bash
helm install --name flux \
--set helmOperator.create=true \
--set git.url=git@github.com:stefanprodan/openfaas-flux \
--set git.chartsPath=charts \
--namespace flux \
weaveworks/flux
```

You can connect Weave Flux to Weave Cloud using a service token:

```bash
helm install --name flux \
--set token=YOUR_WEAVE_CLOUD_SERVICE_TOKEN \
--set helmOperator.create=true \
--set git.url=git@github.com:stefanprodan/openfaas-flux \
--set git.chartsPath=charts \
--namespace flux \
weaveworks/flux
```

Note that Flux Helm Operator works with Kubernetes 1.9 or newer.

### Setup Git sync

At startup, Flux generates a SSH key and logs the public key. 
Find the SSH public key with:

```bash
kubectl -n flux logs deployment/flux | grep identity.pub 
```

In order to sync your cluster state with git you need to copy the public key and 
create a **deploy key** with **write access** on your GitHub repository.

Open GitHub and fork this repo, navigate to your fork, go to _Settings > Deploy keys_ click on _Add deploy key_, check 
_Allow write access_, paste the Flux public key and click _Add key_.

### Install Istio with Weave Flux

The Flux Helm operator provides an extension to Weave Flux that automates Helm Chart releases for it.
A Chart release is described through a Kubernetes custom resource named `FluxHelmRelease`.
The Flux daemon synchronizes these resources from git to the cluster,
and the Flux Helm operator makes sure Helm charts are released as specified in the resources.

Istio release definition:

```yaml
apiVersion: helm.integrations.flux.weave.works/v1alpha2
kind: FluxHelmRelease
metadata:
  name: istio
  namespace: istio-system
  labels:
    chart: istio
spec:
  chartGitPath: istio
  releaseName: istio
  values:
    rbacEnabled: true
    mtls:
      enabled: false
    ingress:
      enabled: true
    ingressgateway:
      enabled: true
    egressgateway:
      enabled: true
    sidecarInjectorWebhook:
      enabled: true
```

### Drive a canary deployment from git 

Exec into `loadtest` pod and start the load test:

```bash
hey -n 1000000 -c 2 -q 5 http://podinfo.test:9898/version
```

**Initial state**

All traffic is routed to the GA deployment:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: podinfo
  namespace: test
spec:
  hosts:
  - podinfo
  - podinfo.weavedx.com
  gateways:
  - mesh
  - podinfo-gateway
  http:
  - route:
#    - destination:
#        host: podinfo
#        subset: canary
#      weight: 0
    - destination:
        host: podinfo
        subset: ga
      weight: 100
```

![s1](https://github.com/stefanprodan/k8s-podinfo/blob/master/docs/screens/istio-c-s1.png)

**Canary warm-up**

Route 10% of the traffic to the canary deployment:

```yaml
  http:
  - route:
    - destination:
        host: podinfo
        subset: canary
      weight: 10
    - destination:
        host: podinfo
        subset: ga
      weight: 90
```

![s2](https://github.com/stefanprodan/k8s-podinfo/blob/master/docs/screens/istio-c-s2.png)

**Canary promotion**

Increase the canary traffic to 60%:

```yaml
  http:
  - route:
    - destination:
        host: podinfo
        subset: canary
      weight: 60
    - destination:
        host: podinfo
        subset: ga
      weight: 40
```

![s3](https://github.com/stefanprodan/k8s-podinfo/blob/master/docs/screens/istio-c-s3.png)

Full promotion, 100% of the traffic to the canary:

```yaml
  http:
  - route:
    - destination:
        host: podinfo
        subset: canary
      weight: 100
#    - destination:
#        host: podinfo
#        subset: ga
#      weight: 0
```

![s4](https://github.com/stefanprodan/k8s-podinfo/blob/master/docs/screens/istio-c-s4.png)

Measure requests latency for each deployment:

![s5](https://github.com/stefanprodan/k8s-podinfo/blob/master/docs/screens/istio-c-s5.png)
 
Observe the traffic shift with Scope:

![s0](https://github.com/stefanprodan/k8s-podinfo/blob/master/docs/screens/istio-c-s0.png)

### Applying GitOps

Prerequisites for automating Istio canary deployments:

* create a cluster config Git repo that contains the desire state of your cluster
* keep the GA and Canary deployment definitions in Git 
* keep the Istio destination rule, virtual service and gateway definitions in Git
* any changes to the above resources are performed via `git commit` instead of `kubectl apply`

Assuming that the GA is version `0.1.0` and the Canary is at `0.2.0`, you would probably 
want to automate the deployment of patches for 0.1.x and 0.2.x. 

Using Weave Cloud you can define a GitOps pipeline that will continuously monitor for new patches 
and will apply them on both GA and Canary deployments using Weave Flux filters:

* `0.1.*` for GA
* `0.2.*` for Canary

Let's assume you've found a performance issue on the Canary by monitoring the request latency graph, for 
some reason the Canary is responding slower than the GA. 

CD GitOps pipeline steps:

* An engineer fixes the latency issue and cuts a new release by tagging the master branch as 0.2.1
* GitHub notifies GCP Container Builder that a new tag has been committed
* GCP Container Builder builds the Docker image, tags it as 0.2.1 and pushes it to Google Container Registry
* Weave Flux detects the new tag on GCR and updates the Canary deployment definition
* Weave Flux commits the Canary deployment definition to GitHub in the cluster repo
* Weave Flux triggers a rolling update of the Canary deployment
* Weave Cloud sends a Slack notification that the 0.2.1 patch has been released 

Once the Canary is fixed you can keep increasing the traffic shift from GA by modifying the weight setting 
and committing the changes in Git. Weave Cloud will detect that the cluster state is out of sync with 
desired state described in git and will apply the changes. 

If you notice that the Canary doesn't behave well under load you can revert the changes in Git and 
Weave Flux will undo the weight settings by applying the desired state from Git on the cluster.

Keep iterating on the Canary code until the SLA is on a par with the GA release. 



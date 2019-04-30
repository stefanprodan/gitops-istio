# gitops-istio

This is a step by step guide on how to set up a GitOps workflow for Istio with Weave Flux and Flagger.
GitOps is a way to do Continuous Delivery, it works by using Git as a source of truth for declarative infrastructure 
and workloads. In practice this means using `git push` instead of `kubectl apply` or `helm upgrade`.

### Prerequisites

You'll need a Kubernetes cluster **v1.11** or newer with `LoadBalancer` support, 
`MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission controllers enabled.

Install Flux CLI, Helm CLI and Tiller:

```bash
brew install fluxctl

brew install kubernetes-helm

kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
--clusterrole=cluster-admin \
--serviceaccount=kube-system:tiller

helm init --service-account --wait tiller
```

Fork this repository and clone it:

```bash
git clone https://github.com/<YOUR-USERNAME>/gitops-istio
cd gitops-istio
```

### Cluster bootstrap with Flux

Install Weave Flux and its Helm Operator by specifying your fork URL:

```bash
./scripts/flux-init.sh git@github.com:<YOUR-USERNAME>/gitops-istio
```

At startup, Flux generates a SSH key and logs the public key. The above command will print the public key. 

In order to sync your cluster state with git you need to copy the public key and create a deploy key with write 
access on your GitHub repository.
Open GitHub and fork this repo, navigate to your fork, go to Settings > Deploy keys click on Add deploy key, 
check Allow write access, paste the Flux public key and click Add key.

After Flux gets access to your repository it will do the following:

* creates the `istio-system` and `prod` namespaces
* creates the Istio CRDs
* installs Istio Helm Release
* installs Flagger Helm Release
* installs Flagger's Grafana Helm Release
* creates the load tester deployment
* creates the frontend deployment and canary
* creates the backend deployment and canary
* creates the Istio public gateway 

![gitops](https://github.com/stefanprodan/openfaas-flux/blob/master/docs/screens/flux-helm-gitops.png)

The Flux Helm operator provides an extension to Weave Flux that automates Helm Chart releases for it. 
A Chart release is described through a Kubernetes custom resource named HelmRelease. 
The Flux daemon synchronizes these resources from git to the cluster, and the Flux Helm operator makes sure 
Helm charts are released as specified in the resources.

Istio Helm Release example:

```yaml
apiVersion: flux.weave.works/v1beta1
kind: HelmRelease
metadata:
  name: istio
  namespace: istio-system
spec:
  releaseName: istio
  chart:
    repository: https://storage.googleapis.com/istio-release/releases/1.1.4/charts
    name: istio
    version: 1.1.4
  values:
    pilot:
      enabled: true
    gateways:
      enabled: true
    sidecarInjectorWebhook:
      enabled: true
    galley:
      enabled: false
    mixer:
      policy:
        enabled: false
      telemetry:
        enabled: true
    prometheus:
      enabled: true
      scrapeInterval: 5s
    tracing:
      enabled: false
```





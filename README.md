# gitops-istio

This is a step by step guide on how to set up a GitOps workflow for Istio with Weave Flux and Flagger.
GitOps is a way to do Continuous Delivery, it works by using Git as a source of truth for declarative infrastructure 
and workloads. In practice this means using `git push` instead of `kubectl apply` or `helm upgrade`.

### Prerequisites

You'll need a Kubernetes cluster **v1.11** or newer with `LoadBalancer` support, 
`MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission controllers enabled.

Install Helm CLI and Tiller:

```bash
brew install kubernetes-helm

kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
--clusterrole=cluster-admin \
--serviceaccount=kube-system:tiller

helm init --service-account --wait tiller
```

Install Flux CLI:

```bash
brew install fluxctl
```

Fork this repository and clone it:

```bash
git clone https://github.com/<YOUR-USERNAME>/gitops-istio
cd gitops-istio
```



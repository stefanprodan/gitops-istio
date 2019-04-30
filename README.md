# GitOps for Istio Canary Deployments

This is a step by step guide on how to set up a GitOps workflow for Istio with Weave Flux and Flagger. 
GitOps is a way to do Continuous Delivery, it works by using Git as a source of truth for declarative infrastructure 
and workloads. In practice this means using `git push` instead of `kubectl apply` or `helm upgrade`.


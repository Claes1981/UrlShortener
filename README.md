# UrlShortener

A minimal .NET 10 web app for a URL shortener service. It exposes a few read-only endpoints for now; the shortening feature arrives later.

The app is intentionally small — for both courses this repository serves, the focus is the infrastructure around it:

- **Kubernetes** — the app as a container image, running on an AKS cluster behind a Traefik ingress, installed with one Helm command and redeployed by a pipeline on every push to `main`.
- **Skalbara Molnapplikationer** (scalable cloud applications) — the app on Azure, both as an App Service web app and as a container (Azure Container Apps), provisioned with Bicep and deployed through GitHub Actions pipelines.

## Kubernetes course

The same app, containerized: the pipeline builds the image and pushes it to GitHub Container Registry, and a Helm chart installs the whole solution on the cluster.

### How to run it

1. Create the pull secret, with a GitHub token that has only `read:packages`. The first line waits for you to
   paste the token:

   ```bash
   printf 'GitHub token: ' && read -rs GHCR_TOKEN && echo

   kubectl create secret docker-registry ghcr-secret \
     --docker-server=ghcr.io \
     --docker-username=claes1981 \
     --docker-password=$GHCR_TOKEN
   ```

2. Create the app's secret:

   ```bash
   kubectl create secret generic beacon-secret \
     --from-literal=BEACON_API_KEY='your-key'
   ```

3. Install the chart:

   ```bash
   helm upgrade --install beacon ./charts/beacon
   ```
A green run of the pipeline: [bump beacon to version 5](https://github.com/Claes1981/UrlShortener/actions/runs/42523216122)

### Architecture

![Beacon on AKS — control plane and node](docs/architecture.png)

The API server is the only way in from the outside to the cluster Control Plane, i e for traffic to manage the cluster. The Scheduler picks a node for the Requests with sufficient resources.
The Kubelet is sort of an orchestrator for the Node (a machine), as it asks the API server what to run and then start the container in the Node.

Executing the `kubectl apply` command to an already running Pod doesn't change that Pod, you would need to also run `kubectl rollout restart` for the changes to take effect.

### How traffic gets in

The ingress controller that runs in the cluster is **Traefik** (in the `traefik` namespace; the Ingress points to it with `ingressClassName: traefik`). Traefik is exposed through its own LoadBalancer service, which gives the cluster its single public IP. The Ingress `beacon` tells Traefik to send all requests for the path `/` to the ClusterIP service `beacon`, and kube-proxy delivers each request to one of the three pods.

An Ingress is needed on top of a Service because a ClusterIP service is only reachable from inside the cluster. Exposing the service directly would mean a NodePort on every node, or a separate public LoadBalancer IP per service — and neither can route by host or path or terminate TLS (Transport Layer Security). An Ingress gives one public entry point that can route to many services; the object itself is only a set of rules, which the controller (Traefik) watches and applies.

### Requirements (status)

The assignment: the app on the cluster with more than one replica, from own manifests, its configuration in a ConfigMap, its traffic through an Ingress, the whole solution installed with one `helm upgrade --install` after two secrets exist, and a pipeline that builds and pushes the image on every push — with a README that explains the architecture with a picture and can be followed from an empty cluster.

- [x] The app runs with three replicas
- [x] Own manifests in `k8s/`
- [x] Configuration from a ConfigMap, not the image
- [x] No real secret committed (`docs/secret.example.yaml` is the example)
- [x] Traffic through an Ingress
- [x] One `helm upgrade --install` after the two secrets exist
- [x] Three values changeable in `values.yaml` without touching a template
- [x] A workflow that builds and pushes to GHCR on every push
- [x] A README that explains the architecture with a picture
- [x] VG: a push to `main` deploys the new version automatically, and the README links a green run (above)

## Repository layout

```
src/UrlShortener.Api/                    The ASP.NET Core minimal API app (incl. Dockerfile)
tests/UrlShortener.Tests/                xUnit endpoint tests
k8s/                                     Kubernetes manifests: deployment, service, configmap, ingress
charts/beacon/                           The Helm chart: those manifests as templates + values.yaml
docs/secret.example.yaml                 The example secret — the real one is never committed
docs/architecture.drawio                 The Kubernetes architecture picture (source)
docs/architecture.png                    The rendered picture, linked from the Architecture section
infra/                                   Bicep: main.bicep (App Service), container.bicep (Container Apps), aks.bicep (the AKS cluster), budget.bicep (cost alert)
.github/workflows/deploy.yml             Web track: build, test, zip-deploy
.github/workflows/deploy-container.yml   Container track: build, test, push image, new revision
.github/workflows/build-and-deploy.yml   Kubernetes track: build, push to GHCR, helm-deploy to AKS
.github/workflows/hello.yml              First test workflow (week 36 exercise)
scripts/deploy-infra.sh                  Creates the web track from infra/main.bicep
scripts/deploy-container.sh              Creates the container track from infra/container.bicep
scripts/provision-all.sh                 Web track + registry + image + container track in one run
scripts/health-check.sh                  Polls /health until it returns 200
scripts/lab2.sh                          The original Lab 02 az-command script (kept for history)
docs/TUTORIAL.md                         The Skalbara Molnapplikationer step-by-step documentation
docs/FORDJUPNING.md                      Deep-dive work log
requests.http                            Manual endpoint requests (send from any editor)
AGENTS.md                                Constraints for AI coding agents working in this repo
```

## Skalbara Molnapplikationer course

The final assignment was the app running twice in Azure (App Service + Container Apps), each with Bicep, CI/CD, and scaling, documented step by step in [docs/TUTORIAL.md](docs/TUTORIAL.md) — the endpoints, local development, and the provisioning, deploying, scaling and verifying of both tracks.

### Requirements (status)

- [x] .NET 10 app with `/health`, test project, local ports 5001/7001
- [x] Dockerfile for the container build
- [x] Bicep templates for both deployments
- [x] GitHub Actions workflows building and deploying to Azure
- [x] Shell script(s) automating a deployment step
- [x] `docs/TUTORIAL.md` — the step-by-step documentation

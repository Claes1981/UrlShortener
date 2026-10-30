# UrlShortener

A minimal .NET 10 web app for a URL shortener service. It exposes a few read-only endpoints for now; the shortening feature arrives later.

Built as the course project for **Skalbara Molnapplikationer** (scalable cloud applications). The app is intentionally small — the focus of the course is the infrastructure around it: running it on Azure both as an App Service web app and as a container (Azure Container Apps), provisioned with Bicep, deployed through GitHub Actions pipelines, and designed with scaling in mind.

Full documentation: [docs/TUTORIAL.md](docs/TUTORIAL.md) — the endpoints, local development, and the step-by-step for provisioning, deploying, scaling, and verifying both tracks.

## Repository layout

```
src/UrlShortener.Api/                    The ASP.NET Core minimal API app (incl. Dockerfile)
tests/UrlShortener.Tests/                xUnit endpoint tests
infra/                                   Bicep: main.bicep (App Service), container.bicep (Container Apps)
.github/workflows/deploy.yml             Web track: build, test, zip-deploy
.github/workflows/deploy-container.yml   Container track: build, test, push image, new revision
.github/workflows/hello.yml              First test workflow (week 36 exercise)
scripts/deploy-infra.sh                  Creates the web track from infra/main.bicep
scripts/deploy-container.sh              Creates the container track from infra/container.bicep
scripts/provision-all.sh                 Web track + registry + image + container track in one run
scripts/health-check.sh                  Polls /health until it returns 200
scripts/lab2.sh                          The original Lab 02 az-command script (kept for history)
docs/TUTORIAL.md                         The step-by-step documentation
docs/FORDJUPNING.md                      Deep-dive work log
requests.http                            Manual endpoint requests (send from any editor)
AGENTS.md                                Constraints for AI coding agents working in this repo
```

## Course requirements (status)

The final assignment is the app running twice in Azure (App Service + Container Apps), each with Bicep, CI/CD, and scaling, documented in a step-by-step tutorial.

- [x] .NET 10 app with `/health`, test project, local ports 5001/7001
- [x] Dockerfile for the container build
- [x] Bicep templates for both deployments
- [x] GitHub Actions workflows building and deploying to Azure
- [x] Shell script(s) automating a deployment step
- [x] `docs/TUTORIAL.md` — the step-by-step documentation

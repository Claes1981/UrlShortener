# UrlShortener

A minimal .NET 10 web app for a URL shortener service. It exposes a few read-only endpoints for now; the shortening feature arrives later in the course, once the scaling design is settled.

Built as the course project for **Skalbara Molnapplikationer** (scalable cloud applications). The app is intentionally small — the focus of the course is the infrastructure around it: running it on Azure both as an App Service web app and as a container (Azure Container Apps), provisioned with Bicep, deployed through a GitHub Actions pipeline, and designed with scaling in mind.

Full documentation: [docs/TUTORIAL.md](docs/TUTORIAL.md) — the endpoints, local development, deployment and scaling decisions, written to be followed by someone who has never seen the project or Azure before.

## Repository layout

```
src/UrlShortener.Api/        The ASP.NET Core minimal API app
tests/UrlShortener.Tests/    xUnit endpoint tests
docs/TUTORIAL.md             The step-by-step documentation
docs/FORDJUPNING.md          Deep-dive work log
requests.http                Manual endpoint requests (send from any editor)
scripts/lab2.sh              The Lab 02 deploy script (App Service, 3 instances)
AGENTS.md                    Constraints for AI coding agents working in this repo
```

## Course requirements (status)

The final assignment is the app running twice in Azure (App Service + Container Apps), each with Bicep, CI/CD, and scaling, documented in a step-by-step tutorial. The repo will gain as the course progresses:

- [x] .NET 10 app with `/health`, test project, local ports 5001/7001
- [ ] Dockerfile for the container build
- [ ] Bicep templates for both deployments
- [ ] GitHub Actions workflows building and deploying to Azure
- [x] Shell script(s) automating a deployment step
- [ ] `docs/TUTORIAL.md` — the step-by-step documentation

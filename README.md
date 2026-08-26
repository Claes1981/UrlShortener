# UrlShortener

A minimal URL shortener API: create a short code for a long URL and redirect from the short URL back to the original.

Built as the course project for **Skalbara Molnapplikationer** (scalable cloud applications). The app is intentionally small — the focus of the course is the infrastructure around it: running it on Azure both as an App Service web app and as a container (Azure Container Apps), provisioned with Bicep, deployed through a GitHub Actions pipeline, and designed with scaling in mind.

Full documentation: [docs/TUTORIAL.md](docs/TUTORIAL.md).

## Endpoints

| Method | Path      | Description                          |
| ------ | --------- | ------------------------------------ |
| GET    | `/`       | JSON status object                   |
| GET    | `/health` | Health check used by cloud tooling   |

## Repository layout

```
src/UrlShortener.Api/        The ASP.NET Core minimal API app
tests/UrlShortener.Tests/    xUnit endpoint tests
requests.http                Manual endpoint requests (send from any editor)
AGENTS.md                    Constraints for AI coding agents working in this repo
```

## Local development

Prerequisites: .NET 10 SDK.

```sh
dotnet build       # build the app and tests
dotnet run --project src/UrlShortener.Api   # http://localhost:5001
dotnet test        # run the test suite
```

Ports are fixed by the course: **5001** (HTTP) and **7001** (HTTPS). For the HTTPS profile to work, trust the development certificate once:

```sh
dotnet dev-certs https --trust
```

Then verify manually:

```sh
curl http://localhost:5001/health
```

## Course requirements (status)

The final assignment is the app running twice in Azure (App Service + Container Apps), each with Bicep, CI/CD, and scaling, documented in a step-by-step tutorial. The repo will gain as the course progresses:

- [x] .NET 10 app with `/health`, test project, local ports 5001/7001
- [ ] Dockerfile for the container build
- [ ] Bicep templates for both deployments
- [ ] GitHub Actions workflows building and deploying to Azure
- [ ] Shell script(s) automating a deployment step
- [ ] `docs/TUTORIAL.md` — the step-by-step documentation

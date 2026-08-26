# Course constraints (Skalbara molnapplikationer)

- Keep the `src/UrlShortener.Api` path, solution name `UrlShortener.slnx`, and `public partial class Program { }` unchanged — the pipeline (v36), Dockerfile (v38), and App Service (v35) all depend on them. Do not rename.
- `GET /health` MUST NOT be removed or moved; cloud health checks call it (body changes are fine — tests check the status code).
- Course-fixed local ports: http 5001, https 7001. Container listens on 8080 (v38). Do not change launchSettings ports.
- Keep the app boring: a few simple endpoints are enough. Infrastructure is graded, app features are not.
- Course instructions reference the template app "Beacon" — always adapt names and paths to UrlShortener.
- Commit messages: Conventional Commits, imperative mood, English.
- `dev/` is local scratch (commit message drafts); never commit it (`dev/COMMIT/` is git-ignored).

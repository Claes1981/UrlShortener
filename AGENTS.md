# Course constraints (Skal-moln, vecka 35+)

- Keep the `src/UrlShortener` path, solution name `UrlShortener.slnx`, and `public partial class Program { }` unchanged — the pipeline (v36), Dockerfile (v38), and App Service (v35) all depend on them. Do not rename.
- `GET /health` MUST NOT be removed or moved; cloud health checks call it.
- Course-fixed local ports: http 5001, https 7001. Container listens on 8080 (v38). Do not change launchSettings ports.
- Keep the app boring: a few simple endpoints are enough. Infrastructure is graded, app features are not.
- Commit messages in imperative mood, e.g. `Add health endpoint`.
- `dev/` is local scratch (commit message drafts); never commit it.

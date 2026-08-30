# Course constraints (Skalbara molnapplikationer)

- Keep the `src/UrlShortener.Api` path, solution name `UrlShortener.slnx`, and `public partial class Program { }` unchanged — the pipeline (v36), Dockerfile (v38), and App Service (v35) all depend on them. Do not rename.
- `GET /health` MUST NOT be removed or moved; cloud health checks call it (body changes are fine — tests check the status code).
- Course-fixed local ports: http 5001, https 7001; container listens on 8080 (v38). Do not change launchSettings ports. Plain `dotnet run` opens 5001 only (first profile) — 7001 needs `--launch-profile https`.
- Keep the app boring: a few simple endpoints are enough. Infrastructure is graded, app features are not.
- Course instructions reference the template app "Beacon" — always adapt names and paths to UrlShortener.
- Commit messages: Conventional Commits, imperative mood, English.
- `dev/` is local scratch (commit message drafts); never commit it (`dev/COMMIT/` is git-ignored).
- Docs: docs/TUTORIAL.md is the primary document — the course requires updating it the same day the work is done. README.md stays a short pointer; do not duplicate tutorial content. Fördjupning answers live in docs/FORDJUPNING.md (course numbers them continuously).
- Short-code storage: keep it open and stateless until week 39 (Redis). No in-memory or per-instance storage — instances must stay interchangeable.
- Azure: rg-clo25-claes is in westeurope — teacher-approved (swedencentral had no B1 capacity); do not revert it.
- Azure: resources are deleted after each session to stop billing (stopping the app does not stop the plan); scripts/lab2.sh recreates rg-clo25-claes end-to-end.
- This sandbox: dotnet build/test fail with MSB1025 — ask the user to run them locally. Tool output can contain display artifacts (flattened multiline strings, spurious indentation); verify with git or a second read before acting.

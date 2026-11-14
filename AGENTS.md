# Course constraints (Kubernetes, 2026)

- Keep the `src/UrlShortener.Api` path, solution name `UrlShortener.slnx`, and `public partial class Program { }` unchanged — the Dockerfile and build workflow depend on them.
- `GET /health` MUST NOT be removed or moved; cloud health checks and the K8s liveness/readiness probes call it.
- Image and all cluster objects are named `beacon` by course convention; the app code stays UrlShortener.
- Keep the app boring: an API with /health is enough. The course grades Kubernetes, not the app.
- The K8s deliverable is README.md (architecture + picture + link to a green pipeline run). TUTORIAL.md and FORDJUPNING.md belong to the submitted SkalMoln course — do not extend them.
- Never commit real secrets; docs/secret.example.yaml is the example. The Helm chart owns the cluster objects — no kubectl apply on chart-owned objects.
- Local cluster: k3d `clo25` (rancher/k3s:v1.36.4-k3s1), port 8080 forwarded; local dev ports http 5001 / https 7001.
- Commit messages: Herald style (emoji + type(scope): subject, body explains why), English.
- `dev/` is local scratch (commit message drafts); never commit it.
- Azure: use westeurope (Module 04 recommendation); delete resources after each session to stop billing (AKS ≈ 1.50 SEK/hour).
- This sandbox: dotnet build/test fail with MSB1025 — ask the user to run them locally. Verify tool output with git or a second read before acting.

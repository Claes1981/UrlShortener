# Tutorial

It should be possible to follow this tutorial step by step, even if you have never seen the project or Azure before.

## What the app is

A small web app in .NET 10 that will become a URL shortener: you send it a long URL, it hands back a short code, and visiting the short code redirects to the original URL.

So far the app is deliberately much smaller than that, though. Now, it answers three requests:

| Endpoint | What it returns |
| --- | --- |
| GET / | a small JSON object (app name and status) |
| GET /health | status and version; the platform, the pipeline and the container will call this |
| GET /info | which machine answered; used to see load balancing with the naked eye |

## Running it locally

You need the .NET 10 SDK. From the root of the repository:

```bash
dotnet build   # compile
dotnet test    # run the tests
dotnet run --project src/UrlShortener.Api # start the app on http://localhost:5001
```

The course fixes two local ports, 5001 for HTTP and 7001 for HTTPS, but the command above only opens the first one: a plain `dotnet run` starts the first profile in `launchSettings.json` (the `http` profile), which listens on 5001 alone. So while the app is running, this should print 200:

```bash
curl http://localhost:5001/health
```

Port 7001 stays closed until you start the other profile on purpose:

```bash
dotnet run --project src/UrlShortener.Api --launch-profile https
```

That profile serves `https://localhost:7001` with the self-signed development certificate, so `curl https://localhost:7001/health` fails with an SSL error until you trust the certificate once (`dotnet dev-certs https --trust`) or pass `-k` to curl.

There is also a `requests.http` in the root of the repository, runnable from the editor, that talks to both the local app and the app in Azure from the same file.

## Decisions I've made

I chose a URL shortener as app idea, since it was one of the suggested ideas in the assignment instructions. I'm also curious about how such a service works technically.

One sentence per infrastructure choice (the assignment asks *why* each tool fits):

- **.NET 10 minimal API** — the course recommends .NET 10, and the minimal-API style keeps the whole app in one small file, which keeps the focus on the infrastructure instead of the app.
- **Azure App Service (PaaS)** — I don't run my own servers; the platform does load balancing, scaling and health checks, which is exactly what this course is about.
- **Linux instead of Windows** — Linux App Service is cheaper, and the container in week 38 runs on Linux anyway.
- **Basic B1 tier** — the cheapest tier that allows more than one instance; Free and Shared are limited to a single one.
- **Three instances** — the most the Basic tier allows, and enough to prove that the app survives an instance dying.
- **Westeurope instead of Swedencentral** — Sweden Central had no free B1 capacity when I tried; my teacher approved the change (more below).
- **[`scripts/deploy-infra.sh`](../scripts/deploy-infra.sh) and [`scripts/provision-all.sh`](../scripts/provision-all.sh)** — my own scripts: the first builds the web track with one Bicep deployment, the second rebuilds both tracks from an empty subscription in the right order; the assignment asks for at least one own script.

## Provisioning the web track with Bicep (Lab 02 and Lab 04)

All Azure resources carry the course naming pattern `what-clo25-myname`:

| Resource | Name | What it is |
| --- | --- | --- |
| Resource group | `rg-clo25-claes` | the box all resources live in; deleting it deletes everything |
| App Service plan | `asp-clo25-claes` | the compute: B1 (Basic), Linux, Westeurope |
| Web app | `app-clo25-claes` | the app itself, runtime `DOTNETCORE:10.0` |

Lab 02 built these three resources with a script of separate `az` commands ([`scripts/lab2.sh`](../scripts/lab2.sh), still in the repository). In lab 04 the same resources moved into a Bicep template, [`infra/main.bicep`](../infra/main.bicep), with my values in a separate file, [`infra/main.bicepparam`](../infra/main.bicepparam). One command now builds the whole track:

```bash
./scripts/deploy-infra.sh rg-clo25-claes
```

The script does three things:

1. Creates the resource group if it is missing — it usually is, because of the teardown at the end of this section. An empty resource group costs nothing.
2. Runs `az deployment group create` with the template and the parameter file.
3. Prints the app URL back from the template's `appUrl` output, so the next step is `curl https://app-clo25-claes.azurewebsites.net/health` — which should return 200.

If you want to see what a deployment will change before it changes anything:

```bash
./scripts/deploy-infra.sh --what-if rg-clo25-claes
```

The template is where the decisions above live as code: the plan is B1, Linux, with three instances (the most Basic allows); the web app gets `healthCheckPath: /health` so the platform notices when the app stops answering, `alwaysOn: true` so it is not put to sleep between requests, `httpsOnly: true` so plain HTTP is redirected to HTTPS, and `minTlsVersion: '1.3'` as a floor for what clients may speak. The application's code is not in the template at all — infrastructure and application are deployed separately, and that separation is what the pipelines in a later section build on.

After the lecture I tear it down again, because it costs money every hour it runs and nothing is lost — the code, the tests and this tutorial live in the repository, and Azure is the replaceable part:

```bash
az group delete --name rg-clo25-claes --yes --no-wait
az group exists --name rg-clo25-claes   # prints false
```

### What went wrong

The first attempt pointed at Swedencentral, as the lab suggests. Creating the plan failed:

> No available instances to satisfy this request. App Service is attempting to increase capacity. Please retry your request later...

The region simply had no free B1 capacity at that time — capacity for a given tier is a limited, regional resource. My teacher said we could use Westeurope instead, so I changed the location and ran it again. Nothing else had to change.

The first Bicep deployment printed a broken health URL in its output: `https:///health` instead of the real one. The `healthUrl` output in the template was missing the host name in the string, so the URL was assembled from empty parts. The app itself was fine — a broken output value does not break the deployed resource, which is what made it easy to miss. The fix was adding the missing piece to the string; the second run printed the correct URL.

## Seeing the load balancing with my own eyes

The `/info` endpoint was added back in week 34 exactly for this moment: with three instances running, I asked ten times which machine answered.

```bash
for i in $(seq 1 10); do
  curl --silent https://app-clo25-claes.azurewebsites.net/info
  echo
done
```

Ten answers, but only two different machine names came back — the requests were landing on different instances. That is load balancing, visible in plain text. (Two names in ten requests is normal; the third instance simply got none of them this time.)

In the browser, the same question returns the same machine every time. That is not a fault: App Service sets a cookie called `ARRAffinity` by default that binds the browser to one instance, so an app that keeps something in memory does not lose it between requests. `curl` does not store cookies, so it sees all the instances.

The live configuration also shows `"loadBalancing": "LeastRequests"` — the platform sends each request to the instance that is handling the fewest. None of this was configured; it is what PaaS means in practice.

And the consequence worth keeping: if the platform needs a cookie to keep a request on the same machine, an app that depends on that cookie does not scale well. An app that is meant to scale should not keep anything in memory — which is exactly why the decision about where the short codes live is waiting.

## Packaging the same app as a container (Lab 05)

The second track deploys the same app as a container. Same code, same endpoints — only how the app is packaged and where it runs changes.

The Dockerfile lives next to the project, [`src/UrlShortener.Api/Dockerfile`](../src/UrlShortener.Api/Dockerfile), and it has two stages:

```dockerfile
# Stage 1: build the app with the full SDK.
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG PROJECT=src/UrlShortener.Api/UrlShortener.Api.csproj
WORKDIR /src
COPY . .
RUN dotnet restore ./$PROJECT
RUN dotnet publish ./$PROJECT \
  --configuration Release \
  --output /app/publish

# Stage 2: run the app with the runtime only. No SDK, no source code.
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "UrlShortener.Api.dll"]
```

Stage 1 uses the SDK image to restore and publish the project. Stage 2 starts from the runtime-only image and copies in only the published output. That is what a multi-stage build buys: the image that ends up in the registry can only run the app — no compiler, no source files, no `bin/` or `obj/`, which keeps it small and leaves less surface to worry about.

Two details that are easy to get wrong:

- `COPY . .` copies the whole build context — the entire repository — so the [`.dockerignore`](../.dockerignore) at the root excludes build output, `.git/`, the pipeline files, the Bicep templates and IDE files. Without it, every build is slower and the context carries junk the image never uses.
- `ENTRYPOINT ["dotnet", "UrlShortener.Api.dll"]` must name the DLL that `dotnet publish` actually produces. Get it wrong and the container starts, dies at once, and the log says "Could not execute because the specified command or file was not found" — with no hint that the ENTRYPOINT is the problem. The DLL name comes from the project's `AssemblyName`, so check it there.

Before sending anything to Azure, I build the image locally and verify it the same way as everything else in this tutorial — with a health check:

```bash
docker build -t urlshortener:local -f src/UrlShortener.Api/Dockerfile .
docker run --rm --publish 8080:8080 urlshortener:local
```

The app in the container listens on port 8080 — the .NET 10 container default — so the output shows `Now listening on: http://[::]:8080`, and in a second terminal:

```bash
curl http://localhost:8080/health
```

It returns 200, the same check as locally and on Azure.

## Provisioning the container track (Lab 05)

The container track adds three resources to the same resource group:

| Resource | Name | What it is |
| --- | --- | --- |
| Container registry | `acrclo25claes` | Azure Container Registry, Basic tier — where the image lives. Registry names may not contain dashes, so the course naming pattern is written without them |
| Container Apps environment | `cae-clo25-claes` | the managed environment the app runs in |
| Container app | `ca-clo25-claes` | the app itself, with its own public URL |

Container Apps is Azure's PaaS for containers: I declare which container to run, and the platform runs, routes and scales it for me — there is no cluster to administer. The point of having two tracks is that the application code is identical; only the packaging and the platform differ.

Everything is declared in one Bicep template, [`infra/container.bicep`](../infra/container.bicep), with my values in [`infra/container.bicepparam`](../infra/container.bicepparam) — the same pattern as the web track's template. A header comment in the template notes that the course's optional module track would split this file into two; I stayed on the one-file track.

The track needs four steps in a fixed order — what happens when one of them is missing is in What went wrong below.

1. **The web track** — first, so both tracks share the resource group from the start:

   ```bash
   ./scripts/deploy-infra.sh rg-clo25-claes
   ```

2. **The registry** — it must exist before an image can be pushed into it:

   ```bash
   az acr create --resource-group rg-clo25-claes --name acrclo25claes --sku Basic --admin-enabled true
   ```

3. **The image** — built and pushed in the same command, so it is already in the registry when the deployment runs:

   ```bash
   az acr build --registry acrclo25claes --image urlshortener:v1 --file src/UrlShortener.Api/Dockerfile .
   ```

4. **The container track** — the Bicep deployment. The registry from step 2 already exists, so this deployment sees it unchanged and only adds the environment and the app:

   ```bash
   ./scripts/deploy-container.sh rg-clo25-claes
   ```

   The script prints the app's URL from the template's `appUrl` output:

   ```
   Done. App URL: https://ca-clo25-claes.wonderfulflower-6dcb3a59.westeurope.azurecontainerapps.io
   ```

   The middle part of the address belongs to the environment, and it changes every time the track is rebuilt — which is why the script prints it instead of the tutorial hard-coding it. The check is the same as everywhere else:

   ```bash
   curl https://ca-clo25-claes.wonderfulflower-6dcb3a59.westeurope.azurecontainerapps.io/health
   ```

All four steps are in [`scripts/provision-all.sh`](../scripts/provision-all.sh), which rebuilds both tracks from a torn-down state in exactly this order and ends with "Both tracks are up.":

```bash
./scripts/provision-all.sh rg-clo25-claes acrclo25claes
```

That is the command that proves the chain: I ran it once with the resource group deleted, and it brought back the web track answering on `app-clo25-claes.azurewebsites.net` and the container track on the new address above.

### How the image gets in — and how the platform gets it out

There are three different doors into the registry, each using a different identity:

- **Me, from my laptop.** `az acr create` and `az acr build` run under my own `az login`; I am the identity, and nothing else is needed.
- **The pipeline, from GitHub.** The workflow signs in with the course's service principal from the `AZURE_CREDENTIALS` secret and runs the same `az acr build`. There is no human and no stored password there — the identity is the service principal.
- **The platform, pulling.** When the container app starts a replica, the platform must pull the image from the registry. For that, the template turns the registry's admin user on and passes its credentials to the container app: the `loginServer` and the username are plain values in the deployment, but the password is stored as a secret on the container app resource and used by the platform when it pulls — it never appears in the repository, in the parameter file, or in the app's configuration.

That third door is a deliberate trade-off, and the template says so in a comment. Because an admin user exists, its password can be read back from the deployed resource by someone with enough permissions. The better solution is a managed identity on the container app with the `AcrPull` role on the registry: no password exists at all, and there is nothing to leak. The course introduces managed identities in week 40, after this lab, so the admin user is the sanctioned path here — with the understanding that it is not the final answer.

### What went wrong

After one of the teardowns I ran `deploy-container.sh` on its own. The resource group was gone, so the script recreated it, and the template recreated the registry and the environment — then the deployment failed at the container app, because the freshly recreated registry was empty and the image reference pointed at a manifest that did not exist:

> Failed to provision revision for container app 'ca-clo25-claes'. Error details: The following field(s) are either invalid or missing. Field 'template.containers.app.image' is invalid ... MANIFEST_UNKNOWN: manifest tagged by "v1" is not found

The lesson is one sentence: **the template rebuilds structure, not data.** Bicep can recreate the registry, the environment and the app, but nothing in the repository recreates the *image* — it lives only inside the registry, and after a teardown the registry is new and empty. The fix was the missing step, `az acr build`, and then the deployment again. `provision-all.sh` exists so that this order — web track, registry, image, container track — cannot be skipped by accident.

## The two pipelines (Lab 05)

Nothing above is re-run by hand. There are two workflows in [`.github/workflows/`](../.github/workflows/), one per track:

- [`deploy.yml`](../.github/workflows/deploy.yml) — "Build and deploy to App Service"
- [`deploy-container.yml`](../.github/workflows/deploy-container.yml) — "Build and deploy the container to Container Apps"

Both fire on every push to `main` and on manual runs, both ignore markdown-only pushes (so editing this tutorial never deploys anything), and both sign in to Azure with the course service principal from the `AZURE_CREDENTIALS` repository secret — the same pipeline identity as in the container section above. Both also end the same way: [`scripts/health-check.sh`](../scripts/health-check.sh) against the track's `/health`, so a green run is a run where the deployed app actually answers.

### Web track: in-place updates

`deploy.yml` has three jobs — `infra` and `build` run in parallel, and `deploy` waits for both (`needs: [build, infra]`):

- **infra** runs the same [`scripts/deploy-infra.sh`](../scripts/deploy-infra.sh) as the web track section, so the Bicep template is applied on every push: change the template, and the next push carries the change to Azure.
- **build** compiles, runs the tests, publishes, and hands the publish folder to the next job as an artifact.
- **deploy** signs in and hands that package to `azure/webapps-deploy@v3`, which drops it into the same web app.

The deployment strategy is **in-place**: the new files replace the old ones on the same app. The address, the plan and the three instances are unchanged — from the outside, the app simply starts serving new files. Rolling back means putting the old files back: `git revert`, push, and the pipeline does the rest.

### Container track: revision-based updates

`deploy-container.yml` has two jobs — `build-and-push`, and `deploy` waiting on it (`needs`):

- **build-and-push** first runs `dotnet test --configuration Release`. Running the tests builds the app as a side effect, so this one step is build and test at once — there is deliberately no separate `dotnet build`. Then it signs in and runs the same `az acr build` as the container section above, but with two tags: the commit's SHA and `latest`.
- **deploy** signs in and runs `az containerapp update --image acrclo25claes.azurecr.io/urlshortener:<commit SHA>`.

That last command is the deployment strategy, and it differs from the web track in one key way: it does not push files onto running replicas. It registers a **new revision** of the app — same app, different image — and the platform rolls the traffic over to it. The old revisions stay registered, so rolling back is one command that points the app at the old image, not a redeploy of old files.

Two design questions, and my answers:

- **Why do the tests appear in both pipelines?** Because the two tracks deploy two different artifacts — a zip to App Service, an image to the registry — and a green web pipeline says nothing about whether the Dockerfile builds. If the duplication bothered me, the course's answer is a shared build job or a reusable workflow; with two small tracks I kept each pipeline self-contained.
- **Why does the container pipeline have no infra job?** Because `az acr build` needs a registry that exists, and `az containerapp update` needs an app that exists. The web pipeline re-applies its Bicep template on every push; the container pipeline deliberately does not — its environment is built once by `provision-all.sh`, and the pipeline only updates the app. After a teardown the container pipeline will fail until `provision-all.sh` has run again.

### Verifying that the app actually updated

A green run only proves that the commands succeeded — it does not prove that the new image is the one serving traffic. The course's check for that is the revision list:

```bash
az containerapp revision list --resource-group rg-clo25-claes --name ca-clo25-claes --all \
  --query "[].{Rev:name, Active:properties.active}" --output table
```

After the push that changed the `/info` text, it printed:

```
Rev                      Active
-----------------------  --------
ca-clo25-claes--3uuufbt  False
ca-clo25-claes--0000001  False
ca-clo25-claes--0000002  True
```

The active revision `0000002` is the one the pipeline created from that push's SHA, with the first manual deploy and the first manual workflow run still registered behind it. The green run itself is [run 40530690009](https://github.com/Claes1981/UrlShortener/actions/runs/40530690009) — build-and-push in 1m49s, deploy in 34s.

The web track has no revisions to check; it is verified by the pipeline's own last step — the health check that runs after the files are in place. I re-ran the web pipeline on 2026-10-28 and it went green end to end.

## Scaling the container track

The web track scales out on three fixed instances. The container track instead gives the platform a rule: the `scale` block in [`infra/container.bicep`](../infra/container.bicep) starts another replica when one gets busy, and lets it go when it does not.

| Setting | Value | Why this value |
| --- | --- | --- |
| `minReplicas` | 1 | the app should answer the first request immediately — `0` (scale to zero) would add a cold start; 1 is the smallest always-up |
| `maxReplicas` | 5 | the ceiling: this app will not outgrow five replicas of 0.5 CPU / 1 GiB, and the cap keeps the worst-case cost finite |
| `concurrentRequests` | 20 | the trigger: above 20 simultaneous requests on one replica, the platform starts another one |
| `cooldownPeriod` | 300 s | platform default, not set in the template: after a scale-out the rule waits five minutes before it may act again, so a short spike does not flap the replica count up and down |
| `pollingInterval` | 30 s | platform default: how often the platform samples the load when checking the rule |

The live configuration matches the template: `az containerapp show --name ca-clo25-claes --resource-group rg-clo25-claes` prints the same five numbers — the two defaults appear there even though the template never names them.

## Alternatives I considered — how to scale

The full numbers and the reasoning are in [FORDJUPNING.md](FORDJUPNING.md) (Vecka 35, Fördjupning 03). The short version:

| Option | What it means | Cost / month |
| --- | --- | --- |
| Scale-out, 3 × B1 | three small instances | 383.37 kr |
| Scale-up, 1 × B3 | one bigger instance | 504.06 kr |
| Premium, 1 × P1v3 | one Premium instance | 1 263.71 kr |

I chose scale-out: a URL shortener is a small app that will never fill a big machine; three instances keep the app alive while one of them dies, while one big machine is a single point of failure; and it is also the cheapest of the three.

## Security basics

Two things that are true for both tracks:

- **Everything is HTTPS.** The web track sets `httpsOnly: true` and a TLS 1.3 floor in the App Service settings (see the Bicep section above); the container track sets `allowInsecure: false` on the ingress, so plain HTTP is redirected to HTTPS on the container URL as well. The certificate on that URL is the platform's default one — there is nothing for me to manage.
- **No secrets in the repository.** The pipelines sign in with the service principal stored in the `AZURE_CREDENTIALS` repository secret, and the registry password lives as a secret on the container app resource, never in the code, the template or the parameter file — written up in the registry section above, including the one deliberate exception (the registry's admin user) and why it is acceptable here.

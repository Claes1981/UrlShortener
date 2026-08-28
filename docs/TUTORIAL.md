# Tutorial

I try to write this tutorial the same day as I do the work or shortly thereafter, so the details are relatively fresh. It should be possible to follow it step by step, even if you have never seen the project or Azure before.

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
- **[`scripts/lab2.sh`](../scripts/lab2.sh)** — my own script with every deploy command, so rebuilding the whole Azure part takes a few minutes; the assignment asks for at least one own script.

## Deploying to App Service (Lab 02)

All Azure resources carry the course naming pattern `what-clo25-myname`:

| Resource | Name | What it is |
| --- | --- | --- |
| Resource group | `rg-clo25-claes` | the box all resources live in; deleting it deletes everything |
| App Service plan | `asp-clo25-claes` | the compute: B1 (Basic), Linux, Westeurope |
| Web app | `app-clo25-claes` | the app itself, runtime `DOTNETCORE:10.0` |

Everything is in [`scripts/lab2.sh`](../scripts/lab2.sh), in this order:

1. `az group create` — create the resource group
2. `az appservice plan create --sku B1 --is-linux` — create the plan
3. `az webapp create --runtime "DOTNETCORE:10.0"` — create the web app
4. `dotnet publish` — build the app; an MSBuild target zips the result to `artifacts/app.zip`
5. `az webapp deploy --type zip` — upload the zip
6. `curl https://app-clo25-claes.azurewebsites.net/health` — check that it answers 200
7. `az appservice plan update --number-of-workers 3` — scale out to three instances
8. `az webapp config set --generic-configurations health_check_path="/health"` — turn on the platform's health check
9. `az webapp show --query siteConfig.healthCheckPath` — verify that it is set

After the lecture I tear it down again, because it costs money every hour it runs and nothing is lost — the code, the tests and this tutorial live in the repository, and Azure is the replaceable part:

```bash
az group delete --name rg-clo25-claes --yes --no-wait
az group exists --name rg-clo25-claes   # prints false
```

### What went wrong

The first run of the script pointed at Swedencentral, as the lab suggests. Creating the plan failed:

> No available instances to satisfy this request. App Service is attempting to increase capacity. Please retry your request later...

The region simply had no free B1 capacity at that time — capacity for a given tier is a limited, regional resource. My teacher said we could use Westeurope instead, so I changed the `--location` in the script and ran it again. Nothing else had to change.

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

## Alternatives I considered — how to scale

The full numbers and the reasoning are in [FORDJUPNING.md](FORDJUPNING.md) (Vecka 35, Fördjupning 03). The short version:

| Option | What it means | Cost / month |
| --- | --- | --- |
| Scale-out, 3 × B1 | three small instances | 383.37 kr |
| Scale-up, 1 × B3 | one bigger instance | 504.06 kr |
| Premium, 1 × P1v3 | one Premium instance | 1 263.71 kr |

I chose scale-out: a URL shortener is a small app that will never fill a big machine; three instances keep the app alive while one of them dies, while one big machine is a single point of failure; and it is also the cheapest of the three.

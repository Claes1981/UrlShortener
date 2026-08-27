# Fördjupningar (Deep-dives)

Answers and results from the course's optional deep-dives. This file grows as the course progresses: I try to write it down the same day as I do the work, and when [TUTORIAL.md](TUTORIAL.md) is written, I pick what fits from here. Not everything in this file ends up in the tutorial.

## Vecka 34, Pass 01 — Fördjupning 01: what does my app actually cost per month?

Task: work out what the app actually costs per month in the Azure price calculator, and bring three numbers that are used again in Pass 03.

Region: Swedencentral
| Setup | Cost / month |
| --- | --- |
| One B1 instance | 127.79 kr |
| Three B1 instances (scale-out) | 383.37 kr |
| Three B1 instances + Container Registry (Basic) | 431.98 kr |

- **127.79 kr** — one B1 (Basic) instance on Linux. This is the cheapest App Service tier that allows more than one instance; the Free and Shared tiers are limited to a single one.
- **383.37 kr** — scaled out to three instances, which is exactly three times the single-instance price. The exercise asks whether it became exactly three times as much: yes, 127.79 × 3 = 383.37 kr, to the öre. You pay per instance and per hour, so scale-out costs exactly linearly.
- **431.98 kr** — the same three instances plus the Container Registry (Basic) that stores the container image, which adds about 48.61 kr. It becomes relevant from week 38, when the app is deployed as a container to Azure Container Apps instead of a zip to App Service.

The linearity result is what makes "three small or one big" a real question — and exactly what Fördjupning 03 below answers.

## Vecka 35, Pass 03 — Fördjupning 03: three small or one big?

Task: price three small instances against one big machine in the calculator, find the ceiling of the Basic tier, and see why the answer is about more than money.

### The three numbers

Region: Swedencentral
| Option | Machine | What you get | Cost / month |
| --- | --- | --- | --- |
| Scale-out | 3 × B1 (Basic) | three instances; 3 cores and 5.25 GB together | 383.37 kr |
| Scale-up | 1 × B3 (Basic) | one instance; the biggest machine in Basic — 4 cores, 7 GB | 504.06 kr |
| Premium | 1 × P1v3 | one Premium v3 instance | 1 263.71 kr |

The first two numbers sit close to each other: one big machine costs about what three small ones cost, for about the same capacity. It is easy to believe the choice does not matter.

### What the third number buys

P1v3 has fewer cores than my three B1s. I am not paying for more capacity there — I am paying for faster hardware and for features: autoscale, deployment slots, VNet. Worth the money the day I need the features, wasted the day I do not.

### The second question

Before deciding, no matter which number is attractive: **how many machines are allowed to break before the app stops responding?**

- Three instances: two can die and the app still answers.
- One machine (B3 or P1v3): the answer is zero. There is nothing to distribute the traffic to, and no health check in the world helps.

### My choice

Scale-out, 3 × B1, 383.37 kr per month. A URL shortener is a small app that will never fill a big machine; three instances keep the app alive while one of them dies, while one big machine is a single point of failure — and scale-out is also the cheapest of the three. (These are the two sentences that go into TUTORIAL.md: price and availability in one answer.)

## Vecka 35 — Fördjupning 04: seeing the load balancing with my own eyes

Done before the resource group was torn down, as the exercise requires the app to be live.

- Ten `curl` requests to `/info` on the deployed app gave back two of the three machine names — the requests landed on different instances. Two names in ten requests is normal; the third instance simply got none of them that time.
- The browser gives the same machine every time: App Service sets an `ARRAffinity` cookie by default that binds the browser to one instance, so an app that keeps something in memory does not lose it between requests. `curl` does not store cookies, so it sees all instances.
- The live configuration shows `"loadBalancing": "LeastRequests"` — the platform sends each request to the instance handling the fewest. Nothing I configured; that is what PaaS means in practice.

Full version: TUTORIAL.md, section "Seeing the load balancing with my own eyes".

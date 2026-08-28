#!/usr/bin/env bash
# Lab 02: deploy UrlShortener to Azure App Service (week 35)
# Recreates rg-clo25-claes end-to-end; run once, watch it go.
set -euo pipefail

# Works from any directory: the repository root is one level above this script
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GROUP="rg-clo25-claes"
PLAN="asp-clo25-claes"
APP="app-clo25-claes"
URL="https://$APP.azurewebsites.net"
LOCATION="westeurope"
SKU="B1"
INSTANCES=3
APP_ZIP="$ROOT/artifacts/app.zip"
PLAN_TABLE='{Name:name, Tier:sku.name, Instances:sku.capacity}'

provision() {
  az group create --name "$GROUP" --location "$LOCATION"
  az appservice plan create \
    --name "$PLAN" --resource-group "$GROUP" \
    --location "$LOCATION" --sku "$SKU" --is-linux
  az webapp create \
    --name "$APP" --resource-group "$GROUP" \
    --plan "$PLAN" --runtime "DOTNETCORE:10.0"
}

build() {
  # UrlShortener.Api.csproj zips the publish output to artifacts/app.zip
  # (ZipPublishOutput target), so one command builds and packages.
  dotnet publish "$ROOT/src/UrlShortener.Api" -c Release \
    -o "$ROOT/artifacts/publish"
}

deploy() {
  az webapp deploy --resource-group "$GROUP" --name "$APP" \
    --src-path "$APP_ZIP" --type zip
}

verify_health() {
  local status
  status="$(curl --silent --output /dev/null --write-out "%{http_code}" \
    "$URL/health")"
  echo "health: $status"
  if [[ "$status" != "200" ]]; then
    echo "expected 200 from $URL/health, got $status" >&2
    exit 1
  fi
}

configure_health_check() {
  az webapp config set --resource-group "$GROUP" --name "$APP" \
    --generic-configurations health_check_path="/health"
  az webapp show --resource-group "$GROUP" --name "$APP" \
    --query siteConfig.healthCheckPath --output tsv
}

scale_out() {
  az appservice plan list --resource-group "$GROUP" \
    --query "[].$PLAN_TABLE" --output table
  az appservice plan update --name "$PLAN" --resource-group "$GROUP" \
    --number-of-workers "$INSTANCES"
  az appservice plan list --resource-group "$GROUP" \
    --query "[].$PLAN_TABLE" --output table
}

provision
build
deploy
verify_health
scale_out
configure_health_check

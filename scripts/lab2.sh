#!/usr/bin/env bash
az group create --name rg-clo25-claes --location westeurope

az appservice plan create --name asp-clo25-claes --resource-group rg-clo25-claes --location westeurope --sku B1 --is-linux

az webapp create --name app-clo25-claes --resource-group rg-clo25-claes --plan asp-clo25-claes --runtime "DOTNETCORE:10.0"

dotnet publish src/UrlShortener.Api --configuration Release --output artifacts/publish

az webapp deploy --resource-group rg-clo25-claes --name app-clo25-claes --src-path artifacts/app.zip --type zip

curl -s -o /dev/null -w "%{http_code}\n" https://app-clo25-claes.azurewebsites.net/health

az appservice plan list --resource-group rg-clo25-claes --query "[].{Name:name, Tier:sku.name, Instances:sku.capacity}" --output table

az appservice plan update --name asp-clo25-claes --resource-group rg-clo25-claes --number-of-workers 3

az appservice plan list --resource-group rg-clo25-claes --query "[].{Name:name, Tier:sku.name, Instances:sku.capacity}" --output table

az webapp config set --resource-group rg-clo25-claes --name app-clo25-claes --generic-configurations health_check_path="/health"

az webapp show --resource-group rg-clo25-claes --name app-clo25-claes --query siteConfig.healthCheckPath --output tsv

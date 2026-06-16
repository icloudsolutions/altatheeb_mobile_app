# Sync mobile_backend + mobile_admin_web + compose to 167.99.242.212:/home/ems
# and run Docker Compose (admin SPA is built inside the nginx image on the server).
# Requires: OpenSSH client (scp, ssh). Docker on the REMOTE host. Node.js is NOT required locally.
#
# Usage (from repo root altahtheeb-addons):
#   .\altatheeb_mobile_app\deploy\ems\deploy.ps1
# Or from altatheeb_mobile_app:
#   .\deploy\ems\deploy.ps1
#   $env:EMS_DEPLOY_USER = "ubuntu"; .\deploy\ems\deploy.ps1

param(
    [string] $ServerHost = "209.38.212.146",
    [string] $RemoteDir = "/home/ems",
    [string] $SshUser = $(if ($env:EMS_DEPLOY_USER) { $env:EMS_DEPLOY_USER } else { "root" })
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Host "ssh not found. Install OpenSSH Client (Windows Optional Features)." -ForegroundColor Red
    exit 1
}

$Server = "${SshUser}@${ServerHost}"

# altatheeb_mobile_app/ (parent of deploy/)
$MobileAppRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

$AdminSrc = Join-Path $MobileAppRoot "mobile_admin_web"
$BackendSrc = Join-Path $MobileAppRoot "mobile_backend"
if (-not (Test-Path (Join-Path $AdminSrc "package.json"))) {
    Write-Host "Admin web not found at $AdminSrc" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path (Join-Path $BackendSrc "app\main.py"))) {
    Write-Host "Backend not found at $BackendSrc" -ForegroundColor Red
    exit 1
}

Write-Host "=== Preparing remote dirs ===" -ForegroundColor Cyan
ssh $Server "mkdir -p $RemoteDir/nginx/templates $RemoteDir/scripts $RemoteDir/snippets $RemoteDir/data/postgres $RemoteDir/data/redis"

Write-Host "=== Uploading mobile_backend ===" -ForegroundColor Cyan
ssh $Server "rm -rf $RemoteDir/mobile_backend"
scp -r $BackendSrc "${Server}:${RemoteDir}/mobile_backend"

Write-Host "=== Uploading mobile_admin_web (Docker build on server) ===" -ForegroundColor Cyan
ssh $Server "rm -rf $RemoteDir/mobile_admin_web"
scp -r $AdminSrc "${Server}:${RemoteDir}/mobile_admin_web"

Write-Host "=== Uploading compose, nginx, Dockerfile ===" -ForegroundColor Cyan
$EmsDir = $PSScriptRoot
scp (Join-Path $EmsDir "docker-compose.yml") "${Server}:${RemoteDir}/"
scp (Join-Path $EmsDir "Dockerfile.nginx") "${Server}:${RemoteDir}/"
scp (Join-Path $EmsDir "nginx\docker-entrypoint.sh") "${Server}:${RemoteDir}/nginx/"
scp -r (Join-Path $EmsDir "nginx\templates") "${Server}:${RemoteDir}/nginx/"
scp (Join-Path $EmsDir "scripts\obtain-cert.sh") "${Server}:${RemoteDir}/scripts/"
ssh $Server "chmod +x $RemoteDir/scripts/obtain-cert.sh $RemoteDir/nginx/docker-entrypoint.sh"
if (Test-Path (Join-Path $EmsDir "snippets\host-nginx-emsmobile.icloud-solutions.net.conf")) {
    ssh $Server "mkdir -p $RemoteDir/snippets"
    scp (Join-Path $EmsDir "snippets\host-nginx-emsmobile.icloud-solutions.net.conf") "${Server}:${RemoteDir}/snippets/"
}
scp (Join-Path $EmsDir "docker-compose.tls-public.yml") "${Server}:${RemoteDir}/"
scp (Join-Path $EmsDir "context.dockerignore") "${Server}:${RemoteDir}/.dockerignore"

Write-Host "=== Ensuring .env on server ===" -ForegroundColor Cyan
$envExample = Join-Path $EmsDir "env.production.example"
scp $envExample "${Server}:${RemoteDir}/env.production.example"
ssh $Server "test -f $RemoteDir/.env || cp $RemoteDir/env.production.example $RemoteDir/.env"

Write-Host "=== docker compose build && up (remote) ===" -ForegroundColor Green
ssh $Server "cd $RemoteDir && docker compose build && docker compose up -d"

Write-Host "=== Done. After DNS + TLS: https://emsmobile.icloud-solutions.net/healthz (see deploy/ems/README.md) ===" -ForegroundColor Green

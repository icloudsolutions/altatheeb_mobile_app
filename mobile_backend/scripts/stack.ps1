# Control the mobile_backend Docker Compose stack (Postgres, Redis, API, worker).
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("up", "stop", "restart", "down", "ps", "logs")]
    [string] $Command,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Rest
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

switch ($Command) {
    "up" { docker compose up -d }
    "stop" { docker compose stop }
    "restart" { docker compose restart }
    "down" { docker compose down }
    "ps" { docker compose ps }
    "logs" {
        if ($Rest.Count -gt 0) {
            docker compose logs -f @Rest
        } else {
            docker compose logs -f
        }
    }
}

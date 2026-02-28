# OpenClaw One-Click Installer for Windows
# https://github.com/kax168/openclaw-installer
$ErrorActionPreference = "Stop"
$Version = "1.0.0"

function Write-Banner {
  Write-Host ""
  Write-Host "  ╔═══════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "  ║   OpenClaw One-Click Installer    ║" -ForegroundColor Cyan
  Write-Host "  ║            v$Version                 ║" -ForegroundColor Cyan
  Write-Host "  ╚═══════════════════════════════════╝" -ForegroundColor Cyan
  Write-Host ""
}

function Install-NodeJS {
  if (Get-Command node -ErrorAction SilentlyContinue) {
    $ver = (node -v).TrimStart('v')
    $major = [int]($ver.Split('.')[0])
    if ($major -ge 22) {
      Write-Host "[OK] Node.js v$ver installed" -ForegroundColor Green
      return
    }
  }
  Write-Host "[INFO] Installing Node.js 22..." -ForegroundColor Blue
  $url = "https://nodejs.org/dist/v22.12.0/node-v22.12.0-x64.msi"
  $msi = "$env:TEMP\node-install.msi"
  Invoke-WebRequest -Uri $url -OutFile $msi
  Start-Process msiexec -ArgumentList "/i $msi /qn" -Wait
  $env:PATH += ";C:\Program Files\nodejs"
  Write-Host "[OK] Node.js installed" -ForegroundColor Green
}

function Install-OpenClaw {
  Write-Host "[INFO] Installing OpenClaw..." -ForegroundColor Blue
  npm install -g openclaw
  if (Get-Command openclaw -ErrorAction SilentlyContinue) {
    Write-Host "[OK] OpenClaw installed" -ForegroundColor Green
  } else {
    Write-Host "[ERROR] Installation failed" -ForegroundColor Red
    exit 1
  }
}

function Setup-Config {
  Write-Host "[INFO] Configuration wizard..." -ForegroundColor Blue
  $configDir = "$env:USERPROFILE\.openclaw"
  New-Item -ItemType Directory -Force -Path $configDir | Out-Null

  Write-Host "`nSelect AI Provider:"
  Write-Host "  1) Anthropic (Claude)"
  Write-Host "  2) OpenAI (GPT)"
  Write-Host "  3) Google (Gemini)"
  $choice = Read-Host "Choice [1]"
  if (-not $choice) { $choice = "1" }

  switch ($choice) {
    "1" { $provider="anthropic"; $model="claude-sonnet-4-20250514" }
    "2" { $provider="openai"; $model="gpt-4o" }
    "3" { $provider="google"; $model="gemini-2.5-pro" }
    default { $provider="anthropic"; $model="claude-sonnet-4-20250514" }
  }

  $apiKey = Read-Host "API Key"
  if (-not $apiKey) {
    Write-Host "[ERROR] API Key required" -ForegroundColor Red
    exit 1
  }

  $config = @"
{
  "provider": "$provider",
  "model": "$model",
  "apiKey": "$apiKey"
}
"@
  $config | Out-File "$configDir\openclaw.json" -Encoding UTF8
  Write-Host "[OK] Config saved" -ForegroundColor Green
}

function Write-Finish {
  Write-Host ""
  Write-Host "  OpenClaw installed!" -ForegroundColor Green
  Write-Host "  Start:  openclaw gateway start"
  Write-Host ""
  Write-Host "  Get 200+ AI prompts: https://fromlaerkai.store" -ForegroundColor Cyan
  Write-Host "  Community: 记录海对岸" -ForegroundColor Cyan
  Write-Host ""
}

# Main
Write-Banner
Install-NodeJS
Install-OpenClaw
Setup-Config
Write-Finish
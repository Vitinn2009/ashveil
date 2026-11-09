# Gera o APK e publica uma "release" no GitHub com ele anexado.
# O jogo instalado consulta essa release e oferece a atualização.
#
# Antes de usar (uma vez):
#   1. Instale o GitHub CLI (winget install GitHub.cli) e rode: gh auth login
#   2. Crie o repositório e envie o projeto (git remote add origin ...; git push -u origin main)
#   3. Em scripts/autoload/updater.gd, preencha REPO com "usuario/repositorio"
#
# Uso:  powershell -File tools/publish_release.ps1 -Notes "O que mudou nesta versão"
param(
	[string]$Notes = "Nova versão do Ashveil.",
	[string]$Godot = "godot"
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$presets = Get-Content "export_presets.cfg" -Raw
if ($presets -notmatch 'version/name="([^"]+)"') { throw "version/name não encontrado no export_presets.cfg" }
$version = $Matches[1]
$updater = Get-Content "scripts/autoload/updater.gd" -Raw
if ($updater -notmatch 'const VERSION := "([^"]+)"') { throw "VERSION não encontrado no updater.gd" }
if ($Matches[1] -ne $version) { throw "updater.gd tem a versão $($Matches[1]) e o export_presets.cfg tem $version: deixe as duas iguais." }
if ($updater -match 'const REPO := ""') { throw "Preencha REPO em scripts/autoload/updater.gd antes de publicar." }

New-Item -ItemType Directory -Force export | Out-Null
$apk = "export/ashveil.apk"
& $Godot --headless --path . --export-debug "Android" $apk
if (-not (Test-Path $apk)) { throw "O APK não foi gerado." }

$tag = "v$version"
gh release create $tag $apk --title "Ashveil $version" --notes $Notes
Write-Host "Release $tag publicada. Os aparelhos com versão mais antiga vão oferecer a atualização."

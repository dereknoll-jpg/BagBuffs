$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    & npm test
    if ($LASTEXITCODE -ne 0) { throw 'Validation failed.' }
    & (Join-Path $PSScriptRoot 'Export-Assets.ps1')
    New-Item -ItemType Directory -Force (Join-Path $projectRoot 'dist') | Out-Null
    $pocketManifest = Get-Content -LiteralPath (Join-Path $projectRoot 'BagBuffs\BagBuffs.toc') -Raw
    $pocketVersion = [regex]::Match($pocketManifest,'(?m)^## Version: ([\w.\-]+)').Groups[1].Value
    if (-not $pocketVersion) { throw 'Addon version is missing.' }
    $archivePath = Join-Path $projectRoot ("dist\BagBuffs-"+$pocketVersion+'.zip')
    Compress-Archive -LiteralPath (Join-Path $projectRoot 'BagBuffs'),(Join-Path $projectRoot 'PocketBuffs'),(Join-Path $projectRoot 'SatchelSense') -DestinationPath $archivePath -Force
    Write-Output "Built $archivePath"
} finally { Pop-Location }

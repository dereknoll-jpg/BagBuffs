$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'Build.ps1')
$manifest=Get-Content -LiteralPath (Join-Path $projectRoot 'SatchelSense\SatchelSense.toc') -Raw
$version=[regex]::Match($manifest,'(?m)^## Version: ([\w.\-]+)').Groups[1].Value
if (-not $version) { throw 'Addon version is missing.' }
$kitRoot=Join-Path $projectRoot 'release\curseforge'
foreach ($folder in @('addon','images','text','review')) { New-Item -ItemType Directory -Path (Join-Path $kitRoot $folder) -Force | Out-Null }
$addonArchive=Join-Path $projectRoot ("dist\SatchelSense-"+$version+'.zip')
Copy-Item -LiteralPath $addonArchive -Destination (Join-Path $kitRoot 'addon') -Force
foreach ($oldArchive in Get-ChildItem -LiteralPath (Join-Path $kitRoot 'addon') -File -Filter '*.zip') {
    if ($oldArchive.Name -ne [IO.Path]::GetFileName($addonArchive)) { Remove-Item -LiteralPath $oldArchive.FullName }
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'release\START-HERE.txt') -Destination (Join-Path $kitRoot 'START-HERE.txt') -Force
& (Join-Path $PSScriptRoot 'Export-Release-Images.ps1')
foreach ($mapping in @(
    @('SatchelSense-400.png','01-icon-400.png'),
    @('SatchelSense-banner-web.png','02-banner.png'),
    @('SatchelSense-features-web.png','03-features.png'),
    @('SatchelSense-1024.jpg','04-icon-1024.jpg')
)) {
    Copy-Item -LiteralPath (Join-Path $projectRoot ('Branding\'+$mapping[0])) -Destination (Join-Path $kitRoot ('images\'+$mapping[1])) -Force
}
# Remove a superseded upload export, keeping the original master under Branding.
$oldLargeIcon=Join-Path $kitRoot 'images\04-icon-1024.png'
if (Test-Path -LiteralPath $oldLargeIcon) { Remove-Item -LiteralPath $oldLargeIcon }
foreach ($name in @('SUMMARY.txt','DESCRIPTION.md','PROJECT-SETUP.txt','IMAGE-CAPTIONS.txt','UPGRADING.md')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot ('release\'+$name)) -Destination (Join-Path $kitRoot 'text') -Force
}
$description=Get-Content -LiteralPath (Join-Path $projectRoot 'release\DESCRIPTION.md') -Raw
$plain=[regex]::Replace($description,'(?m)^#{1,6} ','').Replace('**','').Replace('*','').Replace('`','')
[IO.File]::WriteAllText((Join-Path $kitRoot 'text\DESCRIPTION.txt'),$plain,[Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath (Join-Path $projectRoot 'SatchelSense\CHANGELOG.txt'),(Join-Path $projectRoot 'SatchelSense\LICENSE.txt') -Destination (Join-Path $kitRoot 'text') -Force
foreach ($name in @('RELEASE-READINESS.md','LIVE-CHECKS.md')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot ('release\'+$name)) -Destination (Join-Path $kitRoot 'review') -Force
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'Branding\RELEASE-ART-PROMPTS.txt') -Destination (Join-Path $kitRoot 'review\ARTWORK-NOTES.txt') -Force

# Verify the actual installable ZIP against every source file, without extraction.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive=[IO.Compression.ZipFile]::OpenRead($addonArchive)
$verified=0
try {
    foreach ($entry in $archive.Entries) {
        if (-not $entry.Name) { continue }
        $relative=$entry.FullName.Replace('\','/')
        if (-not ($relative.StartsWith('SatchelSense/') -or $relative.StartsWith('PocketBuffs/'))) { throw ('Unexpected archive path: '+$relative) }
        $source=Join-Path $projectRoot $relative
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw ('Unexpected archive file: '+$relative) }
        $stream=$entry.Open(); $sha=[Security.Cryptography.SHA256]::Create()
        try { $hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') } finally { $stream.Dispose(); $sha.Dispose() }
        if ($hash -ne (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash) { throw ('Archive hash mismatch: '+$relative) }
        $verified++
    }
} finally { $archive.Dispose() }
$expectedCount=@(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'SatchelSense'),(Join-Path $projectRoot 'PocketBuffs') -Recurse -File).Count
if ($verified -ne $expectedCount) { throw 'Archive source-file count mismatch.' }
Add-Type -AssemblyName System.Drawing
$avatar=[Drawing.Image]::FromFile((Join-Path $kitRoot 'images\01-icon-400.png'))
try { if ($avatar.Width -ne 400 -or $avatar.Height -ne 400) { throw 'Project avatar must be 400x400.' } } finally { $avatar.Dispose() }
if (@(Get-ChildItem -LiteralPath $kitRoot -Recurse -File -Filter '*.gif').Count -ne 0) { throw 'The static release kit should not contain GIFs.' }
foreach ($image in Get-ChildItem -LiteralPath (Join-Path $kitRoot 'images') -File) {
    if ($image.Length -ge 2000000) { throw ('Gallery image exceeds 2 MB: '+$image.Name) }
}
$summary=Get-Content -LiteralPath (Join-Path $kitRoot 'text\SUMMARY.txt') -Raw
if ($summary.Trim().Length -gt 255) { throw 'Project summary is too long.' }
$validation=@"
SatchelSense $version - offline release validation

PASS Lua 5.1 syntax and execution of all addon modules.
PASS discovery, duplicate stacks, filters, saved settings and delayed item data.
PASS manual order, drag/arrow editor sorting and item key persistence.
PASS key conflict confirmation and restoration of underlying key actions.
PASS numerical shared potion cooldowns and readable Recently Bandaged lockouts.
PASS restricted values and guarded combat mutations.
PASS grid dragging, canceled drops, native visibility-driver contract and icon lock toggle.
PASS missed drag-stop recovery, scaled empty-slot drops, exact swaps, persistent slots and append-only item discovery.
PASS legacy per-character import, preserved item keys, native slot aliases and idempotent profile migration.
PASS $verified addon archive files verified by SHA-256 against the source.
PASS original 400x400 PNG project avatar and static gallery files below 2 MB each.
PASS summary length and no GIFs in the release kit.

The native combat driver is modeled offline, not observed in a running client.
Live WoW pointer input, click dispatch, actual item use and combat transitions remain unverified.
The release candidate should be tagged Beta until the live pass is complete.
No game was launched and no project was uploaded or published.
"@
[IO.File]::WriteAllText((Join-Path $kitRoot 'review\VALIDATION.txt'),$validation,[Text.UTF8Encoding]::new($false))
Get-ChildItem -LiteralPath $kitRoot -Recurse -File | Where-Object { $_.Name -ne 'MANIFEST-SHA256.csv' } | ForEach-Object {
    [PSCustomObject]@{File=$_.FullName.Substring($kitRoot.Length+1);Bytes=$_.Length;SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
} | Export-Csv -LiteralPath (Join-Path $kitRoot 'MANIFEST-SHA256.csv') -NoTypeInformation -Encoding utf8
$kitArchive=Join-Path $projectRoot ("dist\SatchelSense-CurseForge-Kit-"+$version+'.zip')
Compress-Archive -LiteralPath $kitRoot -DestinationPath $kitArchive -Force
Write-Output ('Prepared '+$kitArchive)
Write-Output ('Verified '+$verified+' addon files. Artwork, listing text, upload guide and readiness notes included.')

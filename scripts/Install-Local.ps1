$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$gameRoot=[IO.Path]::GetFullPath('E:\World of Warcraft\_forever_\Interface\AddOns')
$backupParent=[IO.Path]::GetFullPath((Join-Path $projectRoot 'backups'))
$backupRoot=[IO.Path]::GetFullPath((Join-Path $backupParent ('before-bagbuffs-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))))
$names=@('BagBuffs','SatchelSense','PocketBuffs')
if (-not (Test-Path -LiteralPath $gameRoot -PathType Container)) { throw 'WoW Forever AddOns folder was not found.' }
if (-not $backupRoot.StartsWith($backupParent+[IO.Path]::DirectorySeparatorChar)) { throw 'Unexpected backup path.' }
foreach ($name in $names) {
    $source=Join-Path $projectRoot $name
    $target=[IO.Path]::GetFullPath((Join-Path $gameRoot $name))
    if ([IO.Path]::GetDirectoryName($target) -ne $gameRoot) { throw 'Unexpected addon target.' }
    if (-not (Test-Path -LiteralPath (Join-Path $source ($name+'.toc')) -PathType Leaf)) { throw ('Source manifest missing: '+$name) }
    if (Test-Path -LiteralPath $target) {
        $item=Get-Item -LiteralPath $target
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing to replace a linked addon folder.' }
        $installed=Get-Content -LiteralPath (Join-Path $target ($name+'.toc')) -Raw
        if ($installed -notmatch '(?m)^## Author: Derek\s*$' -or $installed -notmatch '(?m)^## Title: (PocketBuffs|SatchelSense|BagBuffs)( - (SatchelSense )?Settings Import)?\s*$') {
            throw ('Another addon occupies the required folder: '+$name)
        }
    }
}
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
$moved=@(); $created=@()
try {
    foreach ($name in $names) {
        $target=[IO.Path]::GetFullPath((Join-Path $gameRoot $name))
        $backup=[IO.Path]::GetFullPath((Join-Path $backupRoot $name))
        if ([IO.Path]::GetDirectoryName($target) -ne $gameRoot -or [IO.Path]::GetDirectoryName($backup) -ne $backupRoot) { throw 'Unexpected move paths.' }
        if (Test-Path -LiteralPath $target) { Move-Item -LiteralPath $target -Destination $backup; $moved+=$name }
    }
    foreach ($name in $names) {
        $source=Join-Path $projectRoot $name; $target=Join-Path $gameRoot $name
        $created+=$name; Copy-Item -LiteralPath $source -Destination $target -Recurse
        foreach ($file in Get-ChildItem -LiteralPath $source -Recurse -File) {
            $relative=$file.FullName.Substring($source.Length+1)
            if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath (Join-Path $target $relative)).Hash) { throw ('Install verification failed: '+$name+'/'+$relative) }
        }
    }
} catch {
    $failure=$_
    foreach ($name in $created) {
        $target=[IO.Path]::GetFullPath((Join-Path $gameRoot $name)); $failed=[IO.Path]::GetFullPath((Join-Path $backupRoot ('failed-'+$name)))
        if ([IO.Path]::GetDirectoryName($target) -ne $gameRoot -or [IO.Path]::GetDirectoryName($failed) -ne $backupRoot) { throw 'Unexpected recovery paths.' }
        if (Test-Path -LiteralPath $target) { Move-Item -LiteralPath $target -Destination $failed }
    }
    foreach ($name in $moved) {
        $backup=[IO.Path]::GetFullPath((Join-Path $backupRoot $name)); $target=[IO.Path]::GetFullPath((Join-Path $gameRoot $name))
        if ([IO.Path]::GetDirectoryName($target) -ne $gameRoot -or [IO.Path]::GetDirectoryName($backup) -ne $backupRoot) { throw 'Unexpected restore paths.' }
        Move-Item -LiteralPath $backup -Destination $target
    }
    throw $failure
}
Write-Output 'Installed and hash-verified BagBuffs plus both legacy settings loaders.'
Write-Output ('Previous addon files: '+$backupRoot)
Write-Output 'No files under WTF were changed. Restart WoW and keep both BagBuffs Settings Import components enabled.'

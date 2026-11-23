$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot=Split-Path -Parent $PSScriptRoot
$source=[Drawing.Image]::FromFile((Join-Path $projectRoot 'Branding\PocketBuffs-features.png'))
$output=Join-Path $projectRoot 'Branding\PocketBuffs-features-web.png'
try {
    $width=[Math]::Min(1280,$source.Width)
    do {
        $height=[int][Math]::Round($source.Height*$width/$source.Width)
        $bitmap=[Drawing.Bitmap]::new($width,$height,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $graphics=[Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.CompositingQuality=[Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.DrawImage($source,0,0,$width,$height)
            $bitmap.Save($output,[Drawing.Imaging.ImageFormat]::Png)
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
        $width=[int][Math]::Floor($width*.9)
    } while ((Get-Item -LiteralPath $output).Length -ge 1900000 -and $width -ge 800)
    if ((Get-Item -LiteralPath $output).Length -ge 2000000) { throw 'Feature image exceeds upload size limit.' }
} finally { $source.Dispose() }
Write-Output ('Exported feature image: '+(Get-Item -LiteralPath $output).Length+' bytes.')

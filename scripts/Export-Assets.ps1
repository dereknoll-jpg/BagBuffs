$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot 'Branding\BagBuffs-master.png'
$sourceImage = [System.Drawing.Image]::FromFile($sourcePath)

function Resize-Art([int]$size) {
    $bitmap = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($sourceImage, 0, 0, $size, $size)
    $graphics.Dispose()
    return ,$bitmap
}

function Save-Tga([System.Drawing.Bitmap]$bitmap, [string]$path) {
    $header = [byte[]]::new(18)
    $header[2] = 2
    [BitConverter]::GetBytes([uint16]$bitmap.Width).CopyTo($header,12)
    [BitConverter]::GetBytes([uint16]$bitmap.Height).CopyTo($header,14)
    $header[16] = 32; $header[17] = 0x28
    $rect = [System.Drawing.Rectangle]::new(0,0,$bitmap.Width,$bitmap.Height)
    $data = $bitmap.LockBits($rect,[System.Drawing.Imaging.ImageLockMode]::ReadOnly,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $pixels = [byte[]]::new($bitmap.Width*$bitmap.Height*4)
        [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0,$pixels,0,$pixels.Length)
        $stream = [System.IO.File]::Create($path)
        try { $stream.Write($header,0,$header.Length); $stream.Write($pixels,0,$pixels.Length) } finally { $stream.Dispose() }
    } finally { $bitmap.UnlockBits($data) }
}

try {
    foreach ($size in @(64,256)) {
        $image = Resize-Art $size
        try {
            $name = if ($size -eq 64) {'AddonIcon'} else {'PouchArt'}
            Save-Tga $image (Join-Path $projectRoot "BagBuffs\Media\$name.tga")
            $image.Save((Join-Path $projectRoot "Branding\BagBuffs-$size.png"),[System.Drawing.Imaging.ImageFormat]::Png)
        } finally { $image.Dispose() }
    }
    foreach ($size in @(400,1024)) {
        $image = Resize-Art $size
        try { $image.Save((Join-Path $projectRoot "Branding\BagBuffs-$size.png"),[System.Drawing.Imaging.ImageFormat]::Png) } finally { $image.Dispose() }
    }
} finally { $sourceImage.Dispose() }
Write-Output 'Exported in-game TGA art and 64, 256, 400 and 1024 px PNG artwork.'

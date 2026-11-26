$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot=Split-Path -Parent $PSScriptRoot
foreach ($kind in @('banner','features')) {
    $source=[Drawing.Image]::FromFile((Join-Path $projectRoot ("Branding\BagBuffs-"+$kind+'.png')))
    $output=Join-Path $projectRoot ("Branding\BagBuffs-"+$kind+'-web.png')
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
        if ((Get-Item -LiteralPath $output).Length -ge 2000000) { throw ('Upload image exceeds limit: '+$kind) }
    } finally { $source.Dispose() }
}
$large=[Drawing.Image]::FromFile((Join-Path $projectRoot 'Branding\BagBuffs-1024.png'))
$jpegCodec=[Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$jpegParameters=[Drawing.Imaging.EncoderParameters]::new(1)
$jpegParameters.Param[0]=[Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality,[long]90)
try { $large.Save((Join-Path $projectRoot 'Branding\BagBuffs-1024.jpg'),$jpegCodec,$jpegParameters) }
finally { $large.Dispose(); $jpegParameters.Dispose() }
Write-Output 'Exported BagBuffs gallery artwork for the 2 MB upload limit.'

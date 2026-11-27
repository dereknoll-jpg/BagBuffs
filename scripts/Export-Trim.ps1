$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$media=Join-Path $root 'BagBuffs\Media'
function Save-Tga([Drawing.Bitmap]$bitmap,[string]$file) {
    $header=[byte[]]::new(18); $header[2]=2; $header[16]=32; $header[17]=0x28
    [BitConverter]::GetBytes([uint16]$bitmap.Width).CopyTo($header,12)
    [BitConverter]::GetBytes([uint16]$bitmap.Height).CopyTo($header,14)
    $data=$bitmap.LockBits([Drawing.Rectangle]::new(0,0,$bitmap.Width,$bitmap.Height),[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $pixels=[byte[]]::new($bitmap.Width*$bitmap.Height*4)
        [Runtime.InteropServices.Marshal]::Copy($data.Scan0,$pixels,0,$pixels.Length)
        $stream=[IO.File]::Create($file)
        try { $stream.Write($header,0,18); $stream.Write($pixels,0,$pixels.Length) } finally { $stream.Dispose() }
    } finally { $bitmap.UnlockBits($data) }
}
function Export-Part([Drawing.Image]$source,[Drawing.Rectangle]$crop,[string]$name) {
    $part=[Drawing.Bitmap]::new(32,32,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics=[Drawing.Graphics]::FromImage($part)
    try {
        $graphics.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($source,[Drawing.Rectangle]::new(0,0,32,32),$crop,[Drawing.GraphicsUnit]::Pixel)
        Save-Tga $part (Join-Path $media ('BagLeather'+$name+'.tga'))
    } finally { $graphics.Dispose(); $part.Dispose() }
}
$source=[Drawing.Image]::FromFile((Join-Path $root 'Branding\BagTrim-leather-master.png'))
try {
    $w=$source.Width; $h=$source.Height
    $cw=[int]($w/4); $ch=[int]($h/4)
    # Bake a complete skin for each of the 64 supported occupied grid shapes.
    # Each long edge is drawn ONCE from the original art, not stamped repeatedly.
    $tabArt=[Drawing.Image]::FromFile((Join-Path $root 'Branding\BagTrim-tab-master.png'))
    $menuArt=[Drawing.Image]::FromFile((Join-Path $root 'Branding\BagBuffs-64.png'))
    $preview=[Drawing.Bitmap]::new(920,620,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $pg=[Drawing.Graphics]::FromImage($preview)
    $pg.Clear([Drawing.Color]::FromArgb(255,28,28,27))
    $font=[Drawing.Font]::new('Arial',12)
    $ink=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,220,210,192))
    $samples=@{'3x3'=@(45,68);'4x2'=@(235,68);'8x1'=@(445,68);'1x8'=@(795,68);'2x4'=@(45,290);'4x4'=@(235,290);'8x3'=@(445,290)}
    try {
        $pg.DrawString('Fitted Bag Trim artwork - design preview, not an in-game screenshot',$font,$ink,20,16)
        for ($columns=1; $columns -le 8; $columns++) { for ($rows=1; $rows -le 8; $rows++) {
            $width=$columns*36+36; $height=$rows*36+36
            $pw=64; $ph=64
            while ($pw -lt $width) { $pw*=2 }; while ($ph -lt $height) { $ph*=2 }
            $skin=[Drawing.Bitmap]::new($pw,$ph,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics=[Drawing.Graphics]::FromImage($skin)
            $graphics.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            try {
                $regions=@(
                    @(0,0,28,28,0,0,$cw,$ch),
                    @(($width-28),0,28,28,($w-$cw),0,$cw,$ch),
                    @(0,($height-28),28,28,0,($h-$ch),$cw,$ch),
                    @(($width-28),($height-28),28,28,($w-$cw),($h-$ch),$cw,$ch),
                    @(28,0,($width-56),28,$cw,0,($w-2*$cw),$ch),
                    @(28,($height-28),($width-56),28,$cw,($h-$ch),($w-2*$cw),$ch),
                    @(0,28,28,($height-56),0,$ch,$cw,($h-2*$ch)),
                    @(($width-28),28,28,($height-56),($w-$cw),$ch,$cw,($h-2*$ch))
                )
                foreach ($r in $regions) {
                    $graphics.DrawImage($source,[Drawing.Rectangle]::new($r[0],$r[1],$r[2],$r[3]),[Drawing.Rectangle]::new($r[4],$r[5],$r[6],$r[7]),[Drawing.GraphicsUnit]::Pixel)
                }
                Save-Tga $skin (Join-Path $media ('BagSkin'+$columns+'x'+$rows+'.tga'))
                $key=[string]$columns+'x'+$rows
                if ($samples.ContainsKey($key)) {
                    $xy=$samples[$key]
                    $pg.DrawString($key,$font,$ink,$xy[0],$xy[1]-23)
                    $pg.DrawImage($tabArt,[Drawing.Rectangle]::new(($xy[0]+[int](($width-36)/2)),($xy[1]+$height-8),36,36))
                    $pg.DrawImage($menuArt,[Drawing.Rectangle]::new(($xy[0]+[int](($width-24)/2)),($xy[1]+$height-2),24,24))
                    $pg.DrawImage($skin,[Drawing.Rectangle]::new($xy[0],$xy[1],$width,$height),[Drawing.Rectangle]::new(0,0,$width,$height),[Drawing.GraphicsUnit]::Pixel)
                }
            } finally { $graphics.Dispose(); $skin.Dispose() }
        } }
        $preview.Save((Join-Path $root 'Branding\BagTrim-fitted-layouts.png'),[Drawing.Imaging.ImageFormat]::Png)
    } finally { $pg.Dispose(); $preview.Dispose(); $font.Dispose(); $ink.Dispose(); $tabArt.Dispose(); $menuArt.Dispose() }

} finally { $source.Dispose() }
$tab=[Drawing.Image]::FromFile((Join-Path $root 'Branding\BagTrim-tab-master.png'))
try { Export-Part $tab ([Drawing.Rectangle]::new(0,0,$tab.Width,$tab.Height)) 'Tab' } finally { $tab.Dispose() }
Write-Output 'Exported 64 fitted, non-repeating bag skins and the integrated menu tab.'

# Generates the icons in web/ (same artwork as lib/widgets/app_logo.dart).
# Run: powershell -ExecutionPolicy Bypass -File tool/generate_icons.ps1
Add-Type -AssemblyName System.Drawing

$web = Join-Path $PSScriptRoot '..\web'
# Dumbbell parts on a 100x100 grid: x, y, width, height, corner radius.
$parts = @(
    @(30, 46.5, 40, 7, 3.5),
    @(24, 29, 9, 42, 4.5), @(67, 29, 9, 42, 4.5),
    @(15.5, 36, 7, 28, 3.5), @(77.5, 36, 7, 28, 3.5),
    @(11, 46.5, 5.5, 7, 2.5), @(83.5, 46.5, 5.5, 7, 2.5)
)

function Add-RoundRect($path, [single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
    $d = 2 * $r
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
}

function New-Icon {
    param(
        [string]$Path,
        [int]$Size,
        [double]$CornerRatio, # 0 = full-bleed square (maskable / Apple)
        [double]$GlyphScale   # dumbbell size relative to the canvas
    )
    $bmp = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $rect = New-Object System.Drawing.RectangleF 0, 0, $Size, $Size
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect,
        ([System.Drawing.ColorTranslator]::FromHtml('#1C2541')),
        ([System.Drawing.ColorTranslator]::FromHtml('#0B132B')), 45.0

    if ($CornerRatio -gt 0) {
        $bg = New-Object System.Drawing.Drawing2D.GraphicsPath
        Add-RoundRect $bg 0 0 $Size $Size ($Size * $CornerRatio)
        $g.FillPath($brush, $bg)
    } else {
        $g.FillRectangle($brush, $rect)
    }

    $glyph = New-Object System.Drawing.Drawing2D.GraphicsPath
    $glyph.FillMode = [System.Drawing.Drawing2D.FillMode]::Winding
    foreach ($p in $parts) { Add-RoundRect $glyph $p[0] $p[1] $p[2] $p[3] $p[4] }
    $rotate = New-Object System.Drawing.Drawing2D.Matrix
    $rotate.RotateAt(-35, (New-Object System.Drawing.PointF 50, 50))
    $glyph.Transform($rotate)
    $place = New-Object System.Drawing.Drawing2D.Matrix
    $place.Translate($Size * (1 - $GlyphScale) / 2, $Size * (1 - $GlyphScale) / 2)
    $place.Scale($Size * $GlyphScale / 100, $Size * $GlyphScale / 100)
    $glyph.Transform($place)
    $coral = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect,
        ([System.Drawing.ColorTranslator]::FromHtml('#FF6B35')),
        ([System.Drawing.ColorTranslator]::FromHtml('#FF8C61')), 45.0
    $g.FillPath($coral, $glyph)
    $coral.Dispose()

    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $brush.Dispose(); $g.Dispose(); $bmp.Dispose()
    Write-Host "Wrote $Path"
}

New-Icon (Join-Path $web 'favicon.png') 64 0.22 0.84
New-Icon (Join-Path $web 'icons\Icon-192.png') 192 0.22 0.84
New-Icon (Join-Path $web 'icons\Icon-512.png') 512 0.22 0.84
# Maskable: glyph inside the safe zone.
New-Icon (Join-Path $web 'icons\Icon-maskable-192.png') 192 0 0.66
New-Icon (Join-Path $web 'icons\Icon-maskable-512.png') 512 0 0.66
# iOS: full square, no transparency.
New-Icon (Join-Path $web 'icons\apple-touch-icon.png') 180 0 0.78

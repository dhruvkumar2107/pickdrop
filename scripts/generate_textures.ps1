param(
    [int]$NoiseSize = 256,
    [int]$MeshSize = 512,
    [long]$JpegQuality = 85
)

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root 'assets\images'
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

function Save-JpegFile {
    param($bitmap, [string]$path, [long]$quality)
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $parameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $parameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $quality)
    $bitmap.Save($path, $codec, $parameters)
}

function Get-MeshColor {
    param(
        [double]$u,
        [double]$v,
        [array]$points,
        [array]$glow,
        [double]$sigma,
        [double]$baseSigma,
        [double]$glowStrength
    )
    $sum = 0.0
    $r = 0.0
    $g = 0.0
    $b = 0.0
    foreach ($point in $points) {
        $dx = $u - $point[0]
        $dy = $v - $point[1]
        $weight = [Math]::Exp(-(($dx * $dx) + ($dy * $dy)) / (2.0 * $baseSigma * $baseSigma))
        $sum += $weight
        $r += $point[2] * $weight
        $g += $point[3] * $weight
        $b += $point[4] * $weight
    }
    $r = $r / $sum
    $g = $g / $sum
    $b = $b / $sum
    if ($null -ne $glow) {
        $gx = $u - $glow[0]
        $gy = $v - $glow[1]
        $glowWeight = [Math]::Exp(-(($gx * $gx) + ($gy * $gy)) / (2.0 * $sigma * $sigma)) * $glowStrength
        if ($glowWeight -gt 1.0) { $glowWeight = 1.0 }
        $r = ($r * (1.0 - $glowWeight)) + ($glow[2] * $glowWeight)
        $g = ($g * (1.0 - $glowWeight)) + ($glow[3] * $glowWeight)
        $b = ($b * (1.0 - $glowWeight)) + ($glow[4] * $glowWeight)
    }
    return @(
        [int][Math]::Round($r),
        [int][Math]::Round($g),
        [int][Math]::Round($b)
    )
}

function Write-Mesh {
    param(
        [string]$path,
        [array]$points,
        [array]$glow,
        [double]$sigma,
        [double]$glowStrength
    )
    $size = $MeshSize
    $bitmap = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
    $data = $bitmap.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $data.Stride
    $buffer = New-Object byte[] ($stride * $size)
    for ($y = 0; $y -lt $size; $y++) {
        $v = $y / [double]($size - 1)
        for ($x = 0; $x -lt $size; $x++) {
            $u = $x / [double]($size - 1)
            $color = Get-MeshColor -u $u -v $v -points $points -glow $glow -sigma $sigma -baseSigma 0.34 -glowStrength $glowStrength
            $index = ($y * $stride) + ($x * 4)
            $buffer[$index] = [byte]$color[2]
            $buffer[$index + 1] = [byte]$color[1]
            $buffer[$index + 2] = [byte]$color[0]
            $buffer[$index + 3] = 255
        }
    }
    [System.Runtime.InteropServices.Marshal]::Copy($buffer, 0, $data.Scan0, $buffer.Length)
    $bitmap.UnlockBits($data)
    Save-JpegFile -bitmap $bitmap -path $path -quality $JpegQuality
    $bitmap.Dispose()
}

$noisePath = Join-Path $outDir 'noise_texture.png'
$random = New-Object System.Random(20261008)
$bitmap = New-Object System.Drawing.Bitmap($NoiseSize, $NoiseSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$rect = New-Object System.Drawing.Rectangle(0, 0, $NoiseSize, $NoiseSize)
$data = $bitmap.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$buffer = New-Object byte[] ($stride * $NoiseSize)
for ($y = 0; $y -lt $NoiseSize; $y++) {
    for ($x = 0; $x -lt $NoiseSize; $x++) {
        $grey = [byte]$random.Next(108, 149)
        $index = ($y * $stride) + ($x * 4)
        $buffer[$index] = $grey
        $buffer[$index + 1] = $grey
        $buffer[$index + 2] = $grey
        $buffer[$index + 3] = 255
    }
}
[System.Runtime.InteropServices.Marshal]::Copy($buffer, 0, $data.Scan0, $buffer.Length)
$bitmap.UnlockBits($data)
$bitmap.Save($noisePath, [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()

$darkPoints = @(
    @(0.12, 0.14, 14, 15, 18),
    @(0.86, 0.10, 14, 15, 18),
    @(0.10, 0.86, 21, 23, 28),
    @(0.90, 0.90, 14, 15, 18),
    @(0.52, 0.55, 21, 23, 28),
    @(0.30, 0.34, 14, 15, 18)
)
$darkGlow = @(0.88, 0.12, 255, 107, 0)
Write-Mesh -path (Join-Path $outDir 'gradient_mesh_dark.jpg') -points $darkPoints -glow $darkGlow -sigma 0.30 -glowStrength 0.45

$lightPoints = @(
    @(0.14, 0.16, 250, 247, 242),
    @(0.88, 0.12, 255, 255, 255),
    @(0.12, 0.88, 255, 255, 255),
    @(0.90, 0.88, 250, 247, 242),
    @(0.50, 0.52, 255, 255, 255),
    @(0.32, 0.36, 250, 247, 242)
)
$lightGlow = @(0.86, 0.86, 201, 162, 75)
Write-Mesh -path (Join-Path $outDir 'gradient_mesh_light.jpg') -points $lightPoints -glow $lightGlow -sigma 0.32 -glowStrength 0.35

Get-ChildItem $outDir -File | Where-Object { $_.Name -in @('noise_texture.png', 'gradient_mesh_dark.jpg', 'gradient_mesh_light.jpg') } | ForEach-Object {
    Write-Output ("{0} {1} bytes" -f $_.Name, $_.Length)
}

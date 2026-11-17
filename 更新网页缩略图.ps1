param([string]$Page)

$ErrorActionPreference = 'Stop'

if (!$Page) {
    $pages = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.html' -File)
    if ($pages.Count -ne 1) { throw 'Pass the HTML file path with -Page.' }
    $Page = $pages[0].FullName
}

$pageFile = Get-Item -LiteralPath $Page
$root = $pageFile.DirectoryName
$rootPrefix = $root.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$html = [IO.File]::ReadAllText($pageFile.FullName)
Add-Type -AssemblyName System.Drawing

$jpeg = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object MimeType -eq 'image/jpeg'
$settings = [Drawing.Imaging.EncoderParameters]::new(1)
$settings.Param[0] = [Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality, [long]78)
$previews = @{}
$versionTime = (Get-Item -LiteralPath $PSCommandPath).LastWriteTimeUtc

function Get-PreviewPath([string]$url) {
    if ($previews.ContainsKey($url)) { return $previews[$url] }

    $relative = [uri]::UnescapeDataString([Net.WebUtility]::HtmlDecode($url))
    $sourcePath = [IO.Path]::GetFullPath([IO.Path]::Combine($root, $relative))
    if (!$sourcePath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) { return $url }

    $source = Get-Item -LiteralPath $sourcePath
    $previews[$url] = $url
    if ($source.Length -le 24KB) { return $url }

    $previewUrl = 'thumbnails/' + $url + '.jpg'
    $previewPath = Join-Path $root ('thumbnails/' + $relative + '.jpg')
    $cached = Get-Item -LiteralPath $previewPath -ErrorAction SilentlyContinue
    if (!$cached -or $cached.LastWriteTimeUtc -lt $source.LastWriteTimeUtc -or
        $cached.LastWriteTimeUtc -lt $versionTime) {
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($previewPath))
        $original = [Drawing.Image]::FromFile($source.FullName)
        try {
            $scale = [Math]::Min(1.0, 400.0 / [Math]::Max($original.Width, $original.Height))
            $width = [Math]::Max(1, [int][Math]::Round($original.Width * $scale))
            $height = [Math]::Max(1, [int][Math]::Round($original.Height * $scale))
            $bitmap = [Drawing.Bitmap]::new($width, $height, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
            try {
                $graphics = [Drawing.Graphics]::FromImage($bitmap)
                try {
                    $graphics.Clear([Drawing.Color]::FromArgb(255, 253, 247))
                    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                    $graphics.DrawImage($original, 0, 0, $width, $height)
                } finally { $graphics.Dispose() }
                $bitmap.Save($previewPath, $jpeg, $settings)
            } finally { $bitmap.Dispose() }
        } finally { $original.Dispose() }
    }

    if ((Get-Item -LiteralPath $previewPath).Length -lt $source.Length) {
        $previews[$url] = $previewUrl
    }
    return $previews[$url]
}

try {
    # The link always points to the original, including on subsequent runs.
    $pattern = '(?<link><a\b[^>]*?\bhref="(?<url>(?![a-z]+:|/|#)[^"?#]+\.(?:jpe?g|png))"[^>]*>\s*)(?<image><img\b[^>]*>)'
    $updated = [regex]::Replace($html, $pattern, {
        param($match)
        $preview = Get-PreviewPath $match.Groups['url'].Value
        $tag = [regex]::Replace($match.Groups['image'].Value, '(?<=\s)src="[^"]+"', { "src=`"$preview`"" })
        if ($tag -notmatch '\sloading=') { $tag = $tag.Insert(4, ' loading="lazy"') }
        if ($tag -notmatch '\sdecoding=') { $tag = $tag.Insert(4, ' decoding="async"') }
        return $match.Groups['link'].Value + $tag
    }, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($updated -cne $html) { [IO.File]::WriteAllText($pageFile.FullName, $updated) }
    $count = @($previews.Values | Where-Object { $_ -like 'thumbnails/*' }).Count
    Write-Output "$count thumbnails linked in $($pageFile.Name)."
} finally { $settings.Dispose() }

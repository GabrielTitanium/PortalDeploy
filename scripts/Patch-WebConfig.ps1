param(
    [Parameter(Mandatory = $true)]
    [string]$TargetFolder
)

$oldUrls = @(
    'https://titanium-salud-cork-qa.saludts.com/',
    'https://sdt-cork-qa.saludts.com/'
)
$newUrl      = 'https://rcsi-cfg.environments.titanium.solutions/'
$totalFiles  = 0
$totalChanges = 0

$configs = Get-ChildItem -Path $TargetFolder -Filter 'Web.config' -Recurse -ErrorAction SilentlyContinue

if ($configs.Count -eq 0) {
    Write-Warning "No Web.config files found under $TargetFolder"
    exit 0
}

foreach ($file in $configs) {
    Write-Host "Processing: $($file.FullName)"

    $content = [System.IO.File]::ReadAllText($file.FullName)
    $fileChanged = 0

    # Strip &#xD;&#xA; and any trailing whitespace/indentation that follows it
    # inside attribute values so the value becomes a clean single line
    $content = $content -replace '&#xD;&#xA;\s*', ' '
    $content = $content.Trim()

    foreach ($old in $oldUrls) {
        $occurrences = ([regex]::Matches($content, [regex]::Escape($old))).Count
        if ($occurrences -gt 0) {
            Write-Host "  Replacing $occurrences occurrence(s) of: $old"
            $content      = $content -replace [regex]::Escape($old), $newUrl
            $fileChanged += $occurrences
        }
    }

    if ($fileChanged -gt 0) {
        $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
        Write-Host "  Saved $fileChanged replacement(s)"
        $totalFiles++
        $totalChanges += $fileChanged
    } else {
        Write-Host "  No matching URLs found - file unchanged"
    }
}

Write-Host ""
Write-Host "PATCH COMPLETE"
Write-Host "  Web.config files modified : $totalFiles"
Write-Host "  Total URL replacements    : $totalChanges"
Write-Host "  New URL applied           : $newUrl"

# Verification: print the patched customHeaders block
Write-Host ""
Write-Host "POST-PATCH VERIFICATION - customHeaders contents:"
foreach ($file in $configs) {
    $patched = [System.IO.File]::ReadAllText($file.FullName)
    $match   = [regex]::Match($patched, '(?s)<customHeaders>.*?</customHeaders>')
    if ($match.Success) {
        Write-Host ""
        Write-Host "File: $($file.FullName)"
        Write-Host $match.Value
    }
}
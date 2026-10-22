$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$envPath = Join-Path $root '.env'
$templatePath = Join-Path $root '.env.example'

if (Test-Path $envPath) {
    $content = [System.IO.File]::ReadAllText($envPath)
} else {
    $content = [System.IO.File]::ReadAllText($templatePath)
}

$pattern = '(?m)^JWT_SECRET=[^\r\n]*'
$entry = [regex]::Match($content, $pattern)
$valid = $false
if ($entry.Success) {
    $value = $entry.Value.Substring('JWT_SECRET='.Length).Trim().Trim('"').Trim("'")
    try {
        $valid = [Convert]::FromBase64String($value).Length -ge 32
    } catch [FormatException] {
        $valid = $false
    }
}

if (-not $valid) {
    $bytes = New-Object byte[] 32
    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $random.GetBytes($bytes) } finally { $random.Dispose() }
    $replacement = 'JWT_SECRET=' + [Convert]::ToBase64String($bytes)
    if ($entry.Success) {
        $content = [regex]::Replace($content, $pattern, $replacement)
    } else {
        $content = $content.TrimEnd() + "`n" + $replacement + "`n"
    }
}

# UTF-8 without BOM works with both Docker Compose and the Python smoke check.
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($envPath, $content, $utf8)
Write-Host '.env ready: JWT key is valid; other settings were preserved.'

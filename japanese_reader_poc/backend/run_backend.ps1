param(
    [string]$HostName = "127.0.0.1",
    [int]$Port = 8000,
    [switch]$Mock
)

$ErrorActionPreference = "Stop"

$RequiredPython = "3.10"
$VenvPython = ".\.venv\Scripts\python.exe"

function New-BackendVenv {
    if (Test-Path ".\.venv") {
        Remove-Item -Recurse -Force ".\.venv"
    }
    py -$RequiredPython -m venv .venv
}

if (-not (Test-Path $VenvPython)) {
    New-BackendVenv
} else {
    $version = & $VenvPython -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    if ($version -ne $RequiredPython) {
        Write-Host "Recreating .venv with Python $RequiredPython. Current .venv uses Python $version."
        New-BackendVenv
    }
}

& $VenvPython -m pip install --upgrade pip
& $VenvPython -m pip install -r requirements.txt

if ($Mock) {
    $env:MOCK_OCR = "1"
    if (-not $env:MOCK_OCR_TEXT) {
        $env:MOCK_OCR_TEXT = -join ([char[]](
            0x65E5, 0x672C, 0x8A9E, 0x3092, 0x52C9, 0x5F37, 0x3057, 0x307E,
            0x3059, 0x3002
        ))
    }
    Write-Host "Starting backend with MOCK OCR. Scans will return sample text."
} else {
    Remove-Item Env:MOCK_OCR -ErrorAction SilentlyContinue
    Remove-Item Env:MOCK_OCR_TEXT -ErrorAction SilentlyContinue
    Write-Host "Starting backend with REAL Google Cloud Vision OCR."
}

& $VenvPython -m uvicorn app.main:app --reload --host $HostName --port $Port

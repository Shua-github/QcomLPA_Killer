$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ARCH_FILE = Join-Path $ScriptDir "arch"

# 读取 arch 文件所有行，去除空行和多余空白
$ARCH_LIST = Get-Content $ARCH_FILE | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

$GOOS = "android"
$OUTPUT_DIR = Join-Path (Join-Path (Get-Location) "module") "lib"

Push-Location ".\go"

if (-not (Test-Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_DIR | Out-Null
}

foreach ($ARCH in $ARCH_LIST) {
    $GOARCH = $ARCH
    $OUTPUT_NAME = "hexpatch_$ARCH"
    $OUTPUT_FILE = Join-Path $OUTPUT_DIR $OUTPUT_NAME
    $env:GOOS = $GOOS
    $env:GOARCH = $GOARCH

    Write-Host "🔨 开始构建架构：$ARCH"

    & go build -v -o $OUTPUT_FILE main.go

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 编译成功：$OUTPUT_FILE"
    } else {
        Write-Host "❌ 编译失败：$ARCH"
        Exit 1
    }
}

Pop-Location

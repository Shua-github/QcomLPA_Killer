$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$archFile = Join-Path $scriptDir "arch"
$archList = Get-Content $archFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
$goOs = "android"
$outputDir = Join-Path (Join-Path (Get-Location) "module") "lib"

Push-Location ".\go"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

foreach ($arch in $archList) {
    $goArch = $arch
    $outputName = "hexpatch_$arch"
    $outputFile = Join-Path $outputDir $outputName
    $env:GOOS = $goOs
    $env:GOARCH = $goArch

    Write-Host "🔨 开始构建架构：$arch"

    & go build -v -o $outputFile main.go

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 编译成功：$outputFile"
    } else {
        Write-Host "❌ 编译失败：$arch"
        Exit 1
    }
}

Pop-Location

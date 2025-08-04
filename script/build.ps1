$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$CurrentDir = Get-Location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SOURCE_DIR = Join-Path $CurrentDir "module"
$TARGET_FILE_DIR = Join-Path $CurrentDir "output"
$TARGET_FILE_NAME = "QcomLPA-Killer.zip"
$zipPath = Join-Path $TARGET_FILE_DIR $TARGET_FILE_NAME
$goPath = Join-Path $ScriptDir "build-go.ps1"

Write-Host "🚀 开始编译 Go 模块..."
& $goPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Go 模块编译失败，终止打包流程"
    Exit 1
}

if (-not (Test-Path $TARGET_FILE_DIR)) {
    New-Item -ItemType Directory -Path $TARGET_FILE_DIR | Out-Null
}

# 拷贝 LICENSE
Copy-Item -Path "LICENSE" -Destination $SOURCE_DIR -Force

# 转换 CRLF -> LF 并使用 UTF-8 无 BOM 写回
Write-Host "🔧 正在将 CRLF 转换为 LF，并使用 UTF-8 无 BOM 写入..."
Get-ChildItem -Path $SOURCE_DIR -Recurse -File |
Where-Object { $_.Extension -in '.txt', '.go', '.md', '.json', '.yaml', '.yml', '.sh', '.ps1' } |
ForEach-Object {
    $content = Get-Content $_.FullName -Raw -Encoding utf8
    $content = $content -replace "`r`n", "`n"
    $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($_.FullName, $content, $utf8NoBomEncoding)
}

Push-Location $SOURCE_DIR

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path * -DestinationPath $zipPath -Force

Remove-Item LICENSE -Force

Pop-Location

if (Test-Path $zipPath) {
    Write-Host "✅ 打包完成: $zipPath"
} else {
    Write-Host "❌ 打包失败，未找到压缩包文件。"
    Exit 1
}

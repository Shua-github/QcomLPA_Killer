$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$currentDir = Get-Location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sourceDir = Join-Path $currentDir "module"
$targetFileDir = Join-Path $currentDir "output"
$targetFileName = "QcomLPA-Killer.zip"
$targetFileSignName = "QcomLPA-Killer-debug-sign.zip"
$zipPath = Join-Path $targetFileDir $targetFileName
$goBuildScript = Join-Path $scriptDir "build-go.ps1"
$libDir = Join-Path $scriptDir "lib"
$zakoSignPath = Join-Path $libDir "zakosign"
$keyPath = Join-Path $libDir "debug_sign.pem"
$signedZipPath = Join-Path $targetFileDir $targetFileSignName

Write-Host "🚀 开始编译 Go 模块..."
& $goBuildScript

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Go 模块编译失败，终止打包流程"
    Exit 1
}

if (-not (Test-Path $targetFileDir)) {
    New-Item -ItemType Directory -Path $targetFileDir | Out-Null
}

# 拷贝 LICENSE
Copy-Item -Path "LICENSE" -Destination $sourceDir -Force

# 转换 CRLF -> LF 并使用 UTF-8 无 BOM 写回
Write-Host "🔧 正在将 CRLF 转换为 LF，并使用 UTF-8 无 BOM 写入..."
Get-ChildItem -Path $sourceDir -Recurse -File |
Where-Object { $_.Extension -in '.txt', '.go', '.md', '.json', '.yaml', '.yml', '.sh', '.ps1' } |
ForEach-Object {
    $content = Get-Content $_.FullName -Raw -Encoding utf8
    $content = $content -replace "`r`n", "`n"
    $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($_.FullName, $content, $utf8NoBomEncoding)
}

Push-Location $sourceDir

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path * -DestinationPath $zipPath -Force

Pop-Location

if (Test-Path $zipPath) {
    Write-Host "✅ 打包完成: $zipPath"
    
    # 检查是否为 Linux 和 x86_64 架构
    if ($IsLinux -and [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq "X64") {
        Write-Host "🔐 正在进行文件签名..."
        
        rm -f $signedZipPath
        chmod +x $zakoSignPath
        & $zakoSignPath sign $zipPath --key $keyPath --output $signedZipPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 签名完成: $signedZipPath"
        } else {
            Write-Host "❌ 签名失败"
            Exit 1
        }
    } else {
        Write-Host "⏩ 跳过签名（需要 Linux x86_64 环境）"
    }
} else {
    Write-Host "❌ 打包失败，未找到压缩包文件。"
    Exit 1
}

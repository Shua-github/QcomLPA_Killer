#!/bin/bash

# 设置变量
ARCH="arm64"
GOOS="android"
GOARCH="$ARCH"
OUTPUT_DIR="../module/lib"
OUTPUT_NAME="hexpatch_$ARCH"

# 进入 go 源码目录
cd ./go || exit 1

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 编译
go build -v -o "$OUTPUT_DIR/$OUTPUT_NAME" main.go

# 检查结果
if [ $? -eq 0 ]; then
    echo "✅ 编译成功：$OUTPUT_DIR/$OUTPUT_NAME"
else
    echo "❌ 编译失败"
    exit 1
fi

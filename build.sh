#!/bin/bash

# 检查是否安装 zip
if ! command -v zip >/dev/null 2>&1; then
    echo "❌ 未检测到 'zip' 命令，请先安装 zip 工具后再运行脚本"
    echo "👉 在 Arch 系统上可以运行：sudo pacman -S zip"
    echo "👉 在 macOS 上可以使用 Homebrew 安装：brew install zip"
    exit 1
fi

# 编译 Go 模块
echo "🚀 开始编译 Go 模块..."
bash ./build-go.sh

# 检查编译是否成功
if [ $? -ne 0 ]; then
    echo "❌ Go 模块编译失败，终止打包流程"
    exit 1
fi

# 定义路径
SOURCE_DIR="./module"
TARGET_FILE_NAME="QcomLPA-Killer.zip"
TARGET_FILE_DIR="./output"

# 确保输出目录存在
mkdir -p "$TARGET_FILE_DIR"

# 把 LICENSE 复制到 SOURCE_DIR
cp LICENSE "$SOURCE_DIR/"

# 进入 SOURCE_DIR
cd "$SOURCE_DIR"

# 打包
zip -r "../$TARGET_FILE_DIR/$TARGET_FILE_NAME" ./*

# 删除打包后的 LICENSE 文件
rm LICENSE  

# 返回初始目录（可选）
cd - >/dev/null

# 提示完成
echo "✅ 打包完成: $(realpath "$TARGET_FILE_DIR/$TARGET_FILE_NAME")"

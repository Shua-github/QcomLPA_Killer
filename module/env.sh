#!/system/bin/sh

# 定义数据存储路径
DATA_DIR="/data/adb/kill_qcom_lpa"
FILE_LIST="$DATA_DIR/file_list"
CACHE_DIR="$DATA_DIR/cache"
LOG_FILE="$DATA_DIR/log.txt"

# 定义十六进制特征码
OLD_HEX="a0000005591010ffffffff8900000100"
NEW_HEX="a0000005591010ffffffff8900000101"

# 定义常量
FIRMWARE_DIR="/vendor/firmware_mnt/image"
MODEM_NAME="modem.*"
RAW_ARCH=$(uname -m)
if [ "$RAW_ARCH" = "aarch64" ] || [ "$RAW_ARCH" = "arm64" ]; then
  ARCH="arm64"
elif echo "$RAW_ARCH" | grep -q "^arm"; then
  ARCH="arm"
else
  ARCH=""
fi
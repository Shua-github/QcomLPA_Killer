#!/system/bin/sh

MODPATH=${0%/*}
DATA_DIR="/data/adb/kill_qcom_lpa"
FILE_LIST="$DATA_DIR/file_list"
CACHE_DIR="$DATA_DIR/cache"
HEXPATCH="$MODPATH/lib/hexpatch_arm64"
OLD_HEX="a0000005591010ffffffff8900000100"
NEW_HEX="a0000005591010ffffffff8900000101"

ui_print () {
    echo "$1"
}

ui_print "**********************************************"
ui_print " QcomLPA-Killer 修补程序"
ui_print " 模块路径: $MODPATH"
ui_print "**********************************************"

ui_print "- 清理旧缓存..."
rm -rf "$CACHE_DIR"
rm -f "$FILE_LIST"
mkdir -p "$CACHE_DIR"

ui_print "- 扫描系统分区并检查特征码..."
while read -r filepath; do
  [ -z "$filepath" ] && continue
  [ ! -f "$filepath" ] && continue
  
  ui_print "- 正在检查文件: $(basename "$filepath")"
  if "$HEXPATCH" -i "$filepath" -h "$OLD_HEX" | grep -q "true"; then
    echo "$filepath" >> "$FILE_LIST"
    ui_print "- 在文件中发现特征码：$(basename "$filepath")"
  fi
done < <(find -L "/vendor/firmware_mnt/image" -type f -name "modem.*" 2>/dev/null)

if [ ! -s "$FILE_LIST" ]; then
  ui_print "  -> 警告: 未找到任何需要修补的文件。"
  ui_print "  -> 此模块可能对您的设备无效。"
  ui_print "**********************************************"
  ui_print "  ❌ 操作未执行。"
  ui_print "**********************************************"
  abort "未找到需要修补的文件"
fi

ui_print "- 开始尝试修补..."
chmod 755 "$HEXPATCH"

while read -r filepath; do
  [ -z "$filepath" ] && continue

  if [ -f "$filepath" ] && [ -r "$filepath" ]; then
    filename=$(basename "$filepath")
    
    if ! command -v md5sum >/dev/null 2>&1; then
        ui_print "  -> 错误: 缺少 md5sum 工具，无法处理 $filename"
        continue
    fi
    
    file_md5=$(md5sum "$filepath" | awk '{print $1}')
    cache_file="$CACHE_DIR/$filename.$file_md5"

    ui_print "  -> 处理中: $filename"

    # 直接尝试修补，并根据退出码判断结果
    if "$HEXPATCH" -i "$filepath" -o "$cache_file" -h "$OLD_HEX" -p "$NEW_HEX"; then
      if [ -s "$cache_file" ]; then
        ui_print "    - 修补成功，已生成缓存文件。"
      else
        ui_print "    - 警告: 工具执行成功但未生成有效文件。"
        rm -f "$cache_file"
      fi
    else
      rm -f "$cache_file"
      abort "    - 修补失败 (未匹配特征码)。"
    fi
  else
    ui_print "  -> 警告: 无法读取文件: $filepath"
  fi
done < "$FILE_LIST"

if [ -n "$(ls -A "$CACHE_DIR")" ]; then
  ui_print "**********************************************"
  ui_print "  🎉 修补成功！"
  ui_print "  请重启手机以应用更改。"
  ui_print "**********************************************"
  exit 0
else
  ui_print "**********************************************"
  ui_print "  ❌ 修补失败或所有文件均无需修补。"
  ui_print "  请检查以上日志获取详细信息。"
  ui_print "**********************************************"
  exit 1
fi
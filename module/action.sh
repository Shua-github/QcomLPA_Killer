#!/system/bin/sh

MODDIR=${0%/*}
. $MODDIR/env.sh
HEXPATCH="$MODDIR/lib/hexpatch_$ARCH"

chmod 755 "$HEXPATCH"

# 辅助函数
ui_print () {
    echo "$1"
}

ui_print "**********************************************"
ui_print " QcomLPA-Killer 修补程序"
ui_print " 模块路径: $MODDIR"
ui_print "**********************************************"

ui_print "扫描系统分区并检查特征码..."
FOUND=false
CLEANED=false
while read -r filepath; do
    [ -z "$filepath" ] && continue
    [ ! -f "$filepath" ] && continue

    ui_print "- 正在检查文件: $(basename "$filepath")"
    result=$("$HEXPATCH" -i "$filepath" -h "$OLD_HEX" 2>&1)
    if echo "$result" | grep -q "true"; then
        ui_print "- 在文件中发现特征码：$(basename "$filepath")"
        if [ "$CLEANED" = false ]; then
            rm -rf "$CACHE_DIR"/*
            rm -f "$FILE_LIST"
            mkdir -p "$CACHE_DIR"
            CLEANED=true
        fi
        echo "$filepath" >> "$FILE_LIST"
        FOUND=true
    fi
done < <(find -L "$FIRMWARE_DIR" -type f -name "$MODEM_NAME" 2>/dev/null)


if [ "$FOUND" = false ]; then
  abort "  -> 未找到新的需要修补的特征码，无需执行修补操作"
fi

ui_print "- 开始尝试修补..."

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
    
    result=$("$HEXPATCH" -i "$filepath" -o "$cache_file" -h "$OLD_HEX" -p "$NEW_HEX" 2>&1)
    if echo "$result" | grep -q "true"; then
      if [ -s "$cache_file" ]; then
        ui_print "    - 修补成功，已生成缓存文件。"
      else
        ui_print "    - 警告: 工具执行成功但未生成有效文件。"
      fi
    else
      abort "    - 修补失败,结果:[$result]"
    fi
  else
    abort "  -> 警告: 无法读取文件: $filepath"
  fi
done < "$FILE_LIST"

if [ -n "$(ls -A "$CACHE_DIR")" ]; then
  ui_print "**********************************************"
  ui_print "  🎉 修补成功！"
  ui_print "  请重启手机以应用更改。"
  ui_print "**********************************************"
else
  ui_print "**********************************************"
  ui_print "  ❌ 修补失败或所有文件均无需修补。"
  ui_print "  请检查以上日志获取详细信息。"
  ui_print "**********************************************"
fi
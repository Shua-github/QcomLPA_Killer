#!/system/bin/sh

SKIPUNZIP=0

DATA_DIR="/data/adb/kill_qcom_lpa"
FILE_LIST="$DATA_DIR/file_list"
CACHE_DIR="$DATA_DIR/cache"
OLD_HEX="a0000005591010ffffffff8900000100"
NEW_HEX="a0000005591010ffffffff8900000101"
HEXPATCH="$MODPATH/lib/hexpatch_arm64"

if [ ! -d "$CACHE_DIR" ]; then
    mkdir -p "$CACHE_DIR"
fi

chmod 755 "$HEXPATCH"

ui_print "**********************************************"
ui_print " QcomLPA-Killer 模块"
ui_print " 模块路径: $MODPATH"
ui_print "- 扫描系统分区并检查特征码..."

rm -f "$FILE_LIST"
FOUND=false

while read -r filepath; do
  [ -z "$filepath" ] && continue
  [ ! -f "$filepath" ] && continue
  
  ui_print "- 正在检查文件: $(basename "$filepath")"
  if "$HEXPATCH" -i "$filepath" -h "$OLD_HEX" | grep -q "true"; then
    echo "$filepath" >> "$FILE_LIST"
    FOUND=true
    ui_print "- 在文件中发现特征码：$(basename "$filepath")"
  fi
done < <(find -L "/vendor/firmware_mnt/image" -type f -name "modem.*" 2>/dev/null)

[ "$FOUND" = false ] && abort "! 未找到需要修补的特征码，模块可能无效于此设备"

ui_print " ✓ 设备兼容性检查通过"
ui_print ""
ui_print " 请选择操作:"
ui_print " [音量+] 立即修补基带"
ui_print " [音量-] 稍后手动修补"
ui_print ""

START_TIME=$(date +%s)
while true ; do
  NOW_TIME=$(date +%s)
  timeout 1 getevent -lc 1 2>&1 | grep KEY_VOLUME > "$TMPDIR/events"
  if [ $(( NOW_TIME - START_TIME )) -gt 9 ]; then
    ui_print " - 10 秒内未检测到输入，默认选择 [稍后手动修补]"
    ui_print " - 您可以稍后在管理器中点击 [执行] 按钮"
    ui_print "   或手动运行 action.sh 脚本执行修补操作"
    break
  elif grep -q KEY_VOLUMEUP "$TMPDIR/events"; then
    ui_print " - 已选择立即修补"

    FOUND_PATCH=false

    while read -r filepath; do
      [ -z "$filepath" ] && continue
      [ ! -f "$filepath" ] && continue

      filename=$(basename "$filepath")
      ui_print "  -> 正在处理: $filename"

      if ! command -v md5sum >/dev/null 2>&1; then
        ui_print "     - 错误: 找不到 md5sum 工具，跳过 $filename"
        continue
      fi

      file_md5=$(md5sum "$filepath" | awk '{print $1}')
      cache_file="$CACHE_DIR/$filename.$file_md5"

      if "$HEXPATCH" -i "$filepath" -h "$OLD_HEX" | grep -q "true"; then
        ui_print "     - 发现特征码，正在修补..."
        if "$HEXPATCH" -i "$filepath" -o "$cache_file" -h "$OLD_HEX" -p "$NEW_HEX" | grep -q "true"; then
          if [ -s "$cache_file" ]; then
            ui_print "     - 修补成功，已保存到缓存"
            FOUND_PATCH=true
          else
            ui_print "     - 错误: 修补失败，生成的缓存文件为空"
            rm -f "$cache_file"
          fi
        else
          ui_print "     - 错误: 修补过程失败"
          rm -f "$cache_file"
        fi
      else
        ui_print "     - 未发现特征码，无需修补"
      fi
    done < "$FILE_LIST"

    if [ "$FOUND_PATCH" = true ]; then
      ui_print " ✓ 修补成功"
      ui_print " - 请重启手机以生效"
    else
      ui_print " ! 修补失败或未修补任何文件"
      ui_print " - 请稍后在管理器中点击 [执行] 按钮重试"
    fi
    break

  elif grep -q KEY_VOLUMEDOWN "$TMPDIR/events"; then
    ui_print " - 已选择稍后手动修补"
    ui_print " - 您可以随时在管理器中点击 [执行] 按钮"
    ui_print "   或手动运行 action.sh 脚本执行修补操作"
    break
  fi
done

ui_print "**********************************************"

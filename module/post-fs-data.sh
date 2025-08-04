#!/system/bin/sh

# 常量
MODDIR=${0%/*}
. $MODDIR/env.sh

# 统一的日志函数
log() {
    echo "$1" >> "$LOG_FILE"
}

log "模块启动，开始执行文件挂载任务。"

# 检查 file_list 是否存在且不为空
if [ ! -s "$FILE_LIST" ]; then
    log "file_list 不存在或为空，跳过挂载。"
    log "这可能是因为您还未在管理器中运行模块的修补动作。"
    exit 0
fi

# 逐行读取文件列表进行挂载
while read -r original_path; do
    # 跳过空行
    [ -z "$original_path" ] && continue

    if [ -f "$original_path" ]; then
        filename=$(basename "$original_path")
        
        # 计算原始文件MD5以定位对应的缓存文件
        if command -v md5sum >/dev/null 2>&1; then
            file_md5=$(md5sum "$original_path" | awk '{print $1}')
        else
            log "错误: 找不到 md5sum 工具，无法处理 $filename"
            continue
        fi
        
        cache_file="$CACHE_DIR/$filename.$file_md5"

        if [ -f "$cache_file" ]; then
            log "准备挂载: $original_path"
            # 使用 bind mount 将缓存文件挂载到原始路径
            mountpoint -q "$original_path" && umount "$original_path"
            mount --bind "$cache_file" "$original_path"
            if [ $? -eq 0 ]; then
                log "  -> 成功挂载 $filename"
            else
                log "  -> 错误: 挂载 $filename 失败！"
            fi
        else
            log "警告: 未找到对应的缓存文件: $cache_file"
            log "  -> 这可能是因为原始文件内容已改变，或修补动作未成功。"
        fi
    else
        log "警告: 原始系统文件不存在: $original_path"
    fi
    # 恢复SLinux上下文
    restorecon "$original_path"
done < "$FILE_LIST"

log "所有挂载任务执行完毕。"
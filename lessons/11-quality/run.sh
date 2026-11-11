#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SOURCE_DIR/../../scripts/common.sh"

check_ffmpeg
require_samples
OUT="$(ensure_out 11-quality)"
IN="$SAMPLES_DIR/sample_h264_aac.mp4"

print_banner "课时 11：画质、速度与可选的硬件加速"
info "输入：$IN"
info "输出目录：$OUT"

# 用 wc + awk 打印人类可读的文件大小，避免 GNU stat / macOS stat 的语法差异。
file_size() {
  wc -c < "$1" | awk '{ printf "%d 字节 (%.1f KiB)", $1, $1/1024 }'
}

info "1) 同一 preset，对比 CRF 18 与 CRF 28 的体积"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p \
  -c:a aac -b:a 128k \
  "$OUT/crf18.mp4"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -c:v libx264 -preset veryfast -crf 28 -pix_fmt yuv420p \
  -c:a aac -b:a 128k \
  "$OUT/crf28.mp4"
ok "CRF 18 体积：$(file_size "$OUT/crf18.mp4")"
ok "CRF 28 体积：$(file_size "$OUT/crf28.mp4")"
info "数字越小画质越好、文件越大。默认为 23。"

info "2) 同一 CRF，对比 ultrafast 与 medium 的体积（更慢的预设通常更省空间）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -c:v libx264 -preset ultrafast -crf 23 -pix_fmt yuv420p \
  -c:a aac -b:a 128k \
  "$OUT/preset_ultrafast.mp4"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
  -c:a aac -b:a 128k \
  "$OUT/preset_medium.mp4"
ok "ultrafast 体积：$(file_size "$OUT/preset_ultrafast.mp4")"
ok "medium    体积：$(file_size "$OUT/preset_medium.mp4")"

info "3) 单遍目标码率（约 800 kbps 视频）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -c:v libx264 -preset veryfast -b:v 800k -pix_fmt yuv420p \
  -c:a aac -b:a 96k \
  "$OUT/bitrate_1pass.mp4"
show_output "$OUT/bitrate_1pass.mp4"

info "4) 两遍编码，同样 800 kbps（第一遍只统计，输出丢到空设备）"
PASSLOG="$OUT/ffpass"
rm -f "$PASSLOG-0.log" "$PASSLOG-0.log.mbtree"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -c:v libx264 -preset veryfast -b:v 800k -pix_fmt yuv420p \
  -pass 1 -passlogfile "$PASSLOG" \
  -an -f null /dev/null
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -c:v libx264 -preset veryfast -b:v 800k -pix_fmt yuv420p \
  -pass 2 -passlogfile "$PASSLOG" \
  -c:a aac -b:a 96k \
  "$OUT/bitrate_2pass.mp4"
show_output "$OUT/bitrate_2pass.mp4"
ok "单遍体积：$(file_size "$OUT/bitrate_1pass.mp4")"
ok "两遍体积：$(file_size "$OUT/bitrate_2pass.mp4")"
# 清理两遍日志，避免误提交
rm -f "$PASSLOG-0.log" "$PASSLOG-0.log.mbtree"

info "5) 提醒：只换容器时用 -c copy，几乎瞬时完成且无世代损失"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -c copy \
  "$OUT/just_remux.mkv"
ok "源文件体积：$(file_size "$IN")"
ok "copy 之后：$(file_size "$OUT/just_remux.mkv")（应非常接近）"

info "6) 可选：macOS VideoToolbox 硬件编码（没有该编码器则跳过，不算失败）"
if has_encoder h264_videotoolbox; then
  ok "检测到 h264_videotoolbox，开始用硬件编码器按 2 Mbps 压一份。"
  set +e
  ffmpeg -hide_banner -loglevel warning -y \
    -i "$IN" \
    -c:v h264_videotoolbox -b:v 2M \
    -c:a aac -b:a 128k \
    "$OUT/h264_videotoolbox.mp4"
  vt_status=$?
  set -e
  if [[ "$vt_status" -eq 0 && -f "$OUT/h264_videotoolbox.mp4" ]]; then
    show_output "$OUT/h264_videotoolbox.mp4"
    ok "VideoToolbox 编码成功。同样码率下画质通常略逊于精心设置的 libx264，但速度更快、更省电。"
  else
    warn "检测到编码器，但这一次硬件编码失败了（退出码 $vt_status）。请改用 libx264。这不影响本课其它结果。"
    rm -f "$OUT/h264_videotoolbox.mp4"
  fi
else
  warn "当前 FFmpeg 没有 h264_videotoolbox。这是 macOS 的 VideoToolbox 编码器，在 Linux 或精简构建上会被跳过，不属于错误。"
  info "在 Mac 上可以用下面的命令自检："
  printf '%s\n' "  ffmpeg -hide_banner -encoders | grep videotoolbox"
  info "若存在，再手动运行："
  printf '%s\n' "  ffmpeg -y -i $IN -c:v h264_videotoolbox -b:v 2M -c:a aac $OUT/h264_videotoolbox.mp4"
fi

printf '\n'
ok "课时 11 完成。全部动手课到此结束。"
printf '%s\n' "建议再浏览项目根目录的 CHEATSHEET.md，里面有常用命令碎片和易错点。"

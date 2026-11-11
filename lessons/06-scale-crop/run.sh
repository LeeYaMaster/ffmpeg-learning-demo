#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SOURCE_DIR/../../scripts/common.sh"

check_ffmpeg
require_samples
OUT="$(ensure_out 06-scale-crop)"
IN="$SAMPLES_DIR/sample_h264_aac.mp4"

print_banner "课时 06：缩放、裁剪、补边与帧率"
info "输入：$IN"
info "输出目录：$OUT"

info "1) 缩到宽度 640，高度用 -2 自动取偶数（面向 yuv420p）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "scale=640:-2" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a copy \
  "$OUT/scaled_640.mp4"
show_output "$OUT/scaled_640.mp4"

info "2) 故意使用奇数分辨率 + yuv420p（预期失败），再给出修复"
printf '\n%s\n' "${C_CYAN}将执行（预期失败）：${C_RESET}"
printf '%s\n' "  ffmpeg -i in.mp4 -vf scale=801:451 -pix_fmt yuv420p odd_should_fail.mp4"
printf '%s\n' "${C_DIM}───${C_RESET}"
set +e
ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "scale=801:451" \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p \
  -an \
  "$OUT/odd_should_fail.mp4"
odd_status=$?
set -e
if [[ "$odd_status" -ne 0 ]]; then
  ok "如预期失败：yuv420p 的宽和高都必须是 2 的倍数。"
  rm -f "$OUT/odd_should_fail.mp4"
else
  warn "这条命令没有失败（少见）。请仍然记住 yuv420p 需要偶数宽高。"
fi

info "修复：显式写出的那一维自己也必须是偶数；-2 只保证「自动计算的那一边」是偶数"
info "所以不要写 scale=801:-2（宽度 801 仍是奇数），应写成 scale=802:-2 或 scale=-2:450"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "scale=802:-2" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -an \
  "$OUT/scaled_odd_fixed.mp4"
show_output "$OUT/scaled_odd_fixed.mp4"

info "3) 从中心裁出 640×360"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "crop=640:360" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a copy \
  "$OUT/cropped_center.mp4"
show_output "$OUT/cropped_center.mp4"

info "4) 先按比例缩小，再 pad 成 720×720 正方形（居中黑边）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "scale=720:720:force_original_aspect_ratio=decrease,pad=720:720:(ow-iw)/2:(oh-ih)/2" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a copy \
  "$OUT/pad_to_square.mp4"
show_output "$OUT/pad_to_square.mp4"

info "5) 把 30fps 降为 15fps（时长不变，帧数大约减半）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "fps=15" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a copy \
  "$OUT/fps_15.mp4"
show_output "$OUT/fps_15.mp4"

printf '\n'
ok "课时 06 完成。下一步是水印、文字、翻转等视频滤镜："
printf '%s\n' "  ./lessons/07-video-filters/run.sh"

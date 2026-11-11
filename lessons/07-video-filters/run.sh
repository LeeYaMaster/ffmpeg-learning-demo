#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SOURCE_DIR/../../scripts/common.sh"

check_ffmpeg
require_samples
require_font
OUT="$(ensure_out 07-video-filters)"
IN="$SAMPLES_DIR/sample_h264_aac.mp4"
LOGO="$SAMPLES_DIR/logo.png"

print_banner "课时 07：视频滤镜与 filtergraph"
info "输入：$IN"
info "输出目录：$OUT"

info "1) 右上角叠加水印（-filter_complex + overlay）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -i "$LOGO" \
  -filter_complex "[0:v][1:v]overlay=W-w-10:10[outv]" \
  -map "[outv]" -map 0:a \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a copy \
  "$OUT/watermark.mp4"
show_output "$OUT/watermark.mp4"

info "2) 左上角烧录文字（drawtext；找不到字体则跳过）"
if [[ -n "${DEMO_FONT:-}" ]]; then
  FONT_ESC="$(ffmpeg_escape "$DEMO_FONT")"
  if [[ "$DEMO_FONT_IS_CJK" == "yes" ]]; then
    TEXT="FFmpeg 滤镜课"
  else
    TEXT="FFmpeg Filter"
  fi
  run_cmd ffmpeg -hide_banner -loglevel error -y \
    -i "$IN" \
    -vf "drawtext=fontfile=${FONT_ESC}:text='${TEXT}':fontcolor=white:fontsize=42:borderw=2:bordercolor=black@0.6:x=24:y=24" \
    -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
    -c:a copy \
    "$OUT/drawtext.mp4"
  show_output "$OUT/drawtext.mp4"
else
  warn "未找到字体，跳过 drawtext。安装系统中文字体或 DejaVu 后再跑本课即可补上。"
fi

info "3) 开头 1 秒淡入，第 7 秒起 1 秒淡出"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "fade=t=in:st=0:d=1,fade=t=out:st=7:d=1" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a copy \
  "$OUT/fade.mp4"
show_output "$OUT/fade.mp4"

info "4) -vf 链式组合：水平翻转 + 提高一点亮度/对比度 + 色相偏转"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "hflip,eq=brightness=0.06:contrast=1.1:saturation=1.15,hue=h=25" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a copy \
  "$OUT/hflip_eq_hue.mp4"
show_output "$OUT/hflip_eq_hue.mp4"

info "5) 小角度旋转（rotate，四周会露出黑边）；90° 请改用 transpose"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "rotate=PI/8:fillcolor=black" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a copy \
  "$OUT/rotate.mp4"
show_output "$OUT/rotate.mp4"

printf '\n'
ok "课时 07 完成。接下来做缩略图、逐秒截图和高画质 GIF："
printf '%s\n' "  ./lessons/08-thumbnails-gif/run.sh"

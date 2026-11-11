#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SOURCE_DIR/../../scripts/common.sh"

check_ffmpeg
require_samples
OUT="$(ensure_out 05-cut-concat)"
IN="$SAMPLES_DIR/sample_h264_aac.mp4"

print_banner "课时 05：剪切、跳转与拼接"
info "输入：$IN"
info "输出目录：$OUT"
info "源片画面上印着时间码。两种切法都会从 2.5 秒附近切 2 秒，对比第一帧即可看到精度差异。"

info "1) 快速切：-ss 在 -i 之前，并使用 -c copy（落到最近的关键帧，可能早于 2.5 秒）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -ss 2.5 -i "$IN" -t 2 -c copy \
  -avoid_negative_ts make_zero \
  "$OUT/fast_copy.mp4"
show_output "$OUT/fast_copy.mp4"

info "2) 精确切：-ss 在 -i 之后，重新编码（切点更准，输出时间戳从 0 起）"
run_cmd ffmpeg -hide_banner -loglevel warning -y \
  -i "$IN" -ss 2.5 -t 2 \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a aac -b:a 96k \
  "$OUT/accurate.mp4"
show_output "$OUT/accurate.mp4"

info "3) 抽出两段切分结果的第一帧，对比画面上的时间码"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$OUT/fast_copy.mp4" -frames:v 1 \
  "$OUT/fast_copy_first_frame.jpg"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$OUT/accurate.mp4" -frames:v 1 \
  "$OUT/accurate_first_frame.jpg"
show_output "$OUT/fast_copy_first_frame.jpg"
show_output "$OUT/accurate_first_frame.jpg"
info "打开这两张 JPG：fast_copy 的时间码往往会落在 2.0 秒附近的 I 帧，accurate 则接近 2.5 秒。"

info "4) concat demuxer：无损拼接 clip_a + clip_b（编码参数相同才能 -c copy）"
LIST="$OUT/concat_list.txt"
# concat 列表里的单引号路径：把路径中的单引号写成 '\'' 
_concat_line() {
  local p="$1"
  local esc
  esc="$(printf '%s' "$p" | sed "s/'/'\\\\''/g")"
  printf "file '%s'\n" "$esc"
}
{
  _concat_line "$SAMPLES_DIR/clip_a.mp4"
  _concat_line "$SAMPLES_DIR/clip_b.mp4"
} > "$LIST"
ok "已写入列表：$LIST"
cat "$LIST" | sed 's/^/    /'

run_cmd ffmpeg -hide_banner -loglevel error -y \
  -f concat -safe 0 -i "$LIST" -c copy \
  "$OUT/concat_demuxer.mp4"
show_output "$OUT/concat_demuxer.mp4"
info "两段各 2 秒，拼接后时长应约为 4 秒。"

info "5) concat 滤镜：同样拼接两段，但会重编码（参数不同时也能用这种）"
run_cmd ffmpeg -hide_banner -loglevel warning -y \
  -i "$SAMPLES_DIR/clip_a.mp4" \
  -i "$SAMPLES_DIR/clip_b.mp4" \
  -filter_complex "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a aac -b:a 96k \
  "$OUT/concat_filter.mp4"
show_output "$OUT/concat_filter.mp4"

printf '\n'
ok "课时 05 完成。建议对比两张 first_frame 图片，然后进入缩放 / 裁剪："
printf '%s\n' "  ./lessons/06-scale-crop/run.sh"

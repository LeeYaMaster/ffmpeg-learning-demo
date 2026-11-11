#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../scripts/common.sh
source "$SOURCE_DIR/../../scripts/common.sh"

check_ffmpeg
require_samples
OUT="$(ensure_out 01-inspect)"
IN="$SAMPLES_DIR/sample_h264_aac.mp4"

print_banner "课时 01：用 ffprobe 查看媒体信息"
info "输入：$IN"
info "输出目录：$OUT"

info "1) 默认概要：封装格式、每条流的编码与基本参数"
run_cmd ffprobe -hide_banner "$IN"

info "2) 只提取关键字段（文本，方便阅读）"
run_cmd ffprobe -hide_banner -v error \
  -show_entries format=format_name,duration,size,bit_rate \
  -show_entries stream=index,codec_type,codec_name,width,height,avg_frame_rate,r_frame_rate,sample_rate,channels,bit_rate \
  -of default=noprint_wrappers=1 \
  "$IN"

info "3) 同一份信息输出为 JSON，写入文件，方便程序处理"
JSON_OUT="$OUT/probe.json"
printf '\n%s\n' "${C_CYAN}将执行：${C_RESET}"
printf '%s\n' "  ffprobe -v error -print_format json -show_format -show_streams $(printf '%q' "$IN") > $(printf '%q' "$JSON_OUT")"
printf '%s\n' "${C_DIM}───${C_RESET}"
ffprobe -v error -print_format json -show_format -show_streams "$IN" > "$JSON_OUT"
show_output "$JSON_OUT"
info "可以用 less 或 jq 查看：  less $JSON_OUT"

info "4) 查看视频流前 12 帧的类型与时间戳（I 帧 = 关键帧）"
FRAMES_OUT="$OUT/frames_head.txt"
printf '\n%s\n' "${C_CYAN}将执行：${C_RESET}"
printf '%s\n' "  ffprobe -v error -select_streams v:0 -read_intervals %+#12 -show_entries frame=key_frame,pts_time,pict_type -of csv=print_section=0 $(printf '%q' "$IN")"
printf '%s\n' "${C_DIM}───${C_RESET}"
# -read_intervals %+#12 只解码前 12 帧，避免读完整段。
# awk 负责排版，并丢掉偶发的 SEI 附加列。
ffprobe -v error -select_streams v:0   -read_intervals "%+#12"   -show_entries frame=key_frame,pts_time,pict_type   -of csv=print_section=0   "$IN" | awk -F',' 'NF>=3 { printf "key_frame=%s  pts=%ss  type=%s\n", $1, $2, $3 }' | tee "$FRAMES_OUT"
ok "前 12 帧已写入 $FRAMES_OUT"
info "key_frame=1 且 type=I 的就是关键帧。本示例大约每秒一个 I 帧（编码时用了 -g 30）。"

printf '\n'
ok "课时 01 完成。建议打开 $JSON_OUT 看一眼结构，然后进入课时 02。"
printf '%s\n' "  ./lessons/02-basics/run.sh"

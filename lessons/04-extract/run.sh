#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SOURCE_DIR/../../scripts/common.sh"

check_ffmpeg
require_samples
OUT="$(ensure_out 04-extract)"
IN="$SAMPLES_DIR/sample_h264_aac.mp4"

print_banner "课时 04：提取流与更换容器"
info "输入：$IN"
info "输出目录：$OUT"

info "1) 只保留视频，-c:v copy，不重新编码"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -map 0:v:0 -c:v copy -an \
  "$OUT/video_only.mp4"
show_output "$OUT/video_only.mp4"

info "2) 只保留音频，AAC 直接拷贝为 .m4a"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -map 0:a:0 -c:a copy -vn \
  "$OUT/audio_copy.m4a"
show_output "$OUT/audio_copy.m4a"

info "3) 同一条音轨转码为 WAV（未压缩 PCM，便于后续做音频实验）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -map 0:a:0 -vn -c:a pcm_s16le \
  "$OUT/audio_to_wav.wav"
show_output "$OUT/audio_to_wav.wav"

info "4) 更换容器：MP4 → MKV，音视频都 copy"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -c copy \
  "$OUT/remux.mkv"
show_output "$OUT/remux.mkv"

info "5) 再换回去：MKV → MP4，仍然 copy（并加上 faststart，方便网络播放）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$OUT/remux.mkv" -c copy -movflags +faststart \
  "$OUT/remux_back.mp4"
show_output "$OUT/remux_back.mp4"

printf '\n'
ok "课时 04 完成。接下来学习剪切、跳转与拼接，这是时间戳最容易出错的一课："
printf '%s\n' "  ./lessons/05-cut-concat/run.sh"

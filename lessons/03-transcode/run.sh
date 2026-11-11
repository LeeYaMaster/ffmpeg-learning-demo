#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SOURCE_DIR/../../scripts/common.sh"

check_ffmpeg
require_samples
OUT="$(ensure_out 03-transcode)"
IN="$SAMPLES_DIR/sample_h264_aac.mp4"

print_banner "课时 03：转码与格式转换（重编码 vs -c copy）"
info "输入：$IN"
info "输出目录：$OUT"

info "1) 重封装：MP4 → MKV，音视频都 -c copy（不重新压缩，速度极快）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -c copy \
  "$OUT/copy_to_mkv.mkv"
show_output "$OUT/copy_to_mkv.mkv"

info "2) 重新编码为更小的 H.264 + AAC（preset faster + CRF 28，体积会明显下降）"
run_cmd ffmpeg -hide_banner -loglevel warning -y \
  -i "$IN" \
  -c:v libx264 -preset faster -crf 28 -pix_fmt yuv420p \
  -c:a aac -b:a 96k \
  -movflags +faststart \
  "$OUT/reencode_h264_aac.mp4"
show_output "$OUT/reencode_h264_aac.mp4"

info "3) 仅音频：分别输出 MP3 / M4A / WAV"
if has_encoder libmp3lame; then
  run_cmd ffmpeg -hide_banner -loglevel error -y \
    -i "$IN" -vn -c:a libmp3lame -q:a 2 \
    "$OUT/audio_only.mp3"
  show_output "$OUT/audio_only.mp3"
else
  warn "当前 FFmpeg 未启用 libmp3lame，跳过 MP3。macOS 上 brew install ffmpeg 通常会带上。"
fi

run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -vn -c:a aac -b:a 128k \
  "$OUT/audio_only.m4a"
show_output "$OUT/audio_only.m4a"

run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -vn -c:a pcm_s16le \
  "$OUT/audio_only.wav"
show_output "$OUT/audio_only.wav"

info "4) 演示陷阱：把 H.264 流拷贝进 WebM 通常会失败（容器不匹配）"
printf '\n%s\n' "${C_CYAN}将执行（预期失败）：${C_RESET}"
printf '%s\n' "  ffmpeg -i in.mp4 -c copy out.webm"
printf '%s\n' "${C_DIM}───${C_RESET}"
set +e
ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -c copy \
  "$OUT/copy_to_webm_should_fail.webm"
copy_webm_status=$?
set -e
if [[ "$copy_webm_status" -ne 0 ]]; then
  ok "如预期失败：H.264 + AAC 不能直接拷贝进 WebM 容器。"
  rm -f "$OUT/copy_to_webm_should_fail.webm"
else
  warn "这次拷贝竟然成功了（你的 FFmpeg 构建可能比较宽松）。请仍然以「WebM 标准编码是 VP8/VP9/AV1 + Vorbis/Opus」为准。"
fi

info "5) 正确做法：转码为 VP9 + Opus 再封装 WebM（若编码器可用）"
if has_encoder libvpx-vp9 && has_encoder libopus; then
  run_cmd ffmpeg -hide_banner -loglevel warning -y \
    -i "$IN" \
    -c:v libvpx-vp9 -crf 32 -b:v 0 -deadline good -cpu-used 4 \
    -c:a libopus -b:a 96k \
    "$OUT/to_webm.webm"
  show_output "$OUT/to_webm.webm"
else
  warn "未检测到 libvpx-vp9 或 libopus，跳过 WebM。可用 ffmpeg -encoders 自行确认。"
fi

printf '\n'
ok "课时 03 完成。对比一下 copy_to_mkv.mkv 与源文件的体积，再进入提取流："
printf '%s\n' "  ./lessons/04-extract/run.sh"

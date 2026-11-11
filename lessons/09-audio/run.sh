#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SOURCE_DIR/../../scripts/common.sh"

check_ffmpeg
require_samples
OUT="$(ensure_out 09-audio)"
VID="$SAMPLES_DIR/sample_h264_aac.mp4"
A440="$SAMPLES_DIR/tone_440.wav"
A660="$SAMPLES_DIR/tone_660.wav"

print_banner "课时 09：音频处理"
info "输出目录：$OUT"

info "1) 简单音量：放大一倍，以及降低 6dB"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$A440" -af "volume=2.0" \
  "$OUT/volume_up.wav"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$A440" -af "volume=-6dB" \
  "$OUT/volume_down.wav"
show_output "$OUT/volume_up.wav"
show_output "$OUT/volume_down.wav"

info "2) loudnorm：按 EBU R128 做单遍响度归一化（目标 -16 LUFS，适合移动端）"
if has_filter loudnorm; then
  run_cmd ffmpeg -hide_banner -loglevel warning -y \
    -i "$VID" \
    -af "loudnorm=I=-16:TP=-1.5:LRA=11" \
    -c:v copy -c:a aac -b:a 128k \
    "$OUT/loudnorm.mp4"
  show_output "$OUT/loudnorm.mp4"
else
  warn "当前 FFmpeg 没有 loudnorm 滤镜，已跳过。可用 -af volume 代替做简单增益。"
fi

info "3) 混合两路正弦波（440Hz + 660Hz）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$A440" -i "$A660" \
  -filter_complex "amix=inputs=2:duration=shortest:normalize=0" \
  "$OUT/mixed.wav"
show_output "$OUT/mixed.wav"

info "4) 去掉原片音轨（静音）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$VID" -c:v copy -an \
  "$OUT/muted.mp4"
show_output "$OUT/muted.mp4"

info "5) 用 660Hz 正弦波替换原片音轨（视频 copy，按较短的一路截断）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$VID" -i "$A660" \
  -map 0:v:0 -map 1:a:0 \
  -c:v copy -c:a aac -b:a 96k -shortest \
  "$OUT/replaced_audio.mp4"
show_output "$OUT/replaced_audio.mp4"

info "6) 音频淡入 1 秒、从第 5 秒起淡出 1 秒（素材长 6 秒）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$A440" \
  -af "afade=t=in:st=0:d=1,afade=t=out:st=5:d=1" \
  "$OUT/fade.wav"
show_output "$OUT/fade.wav"

info "7) 改采样率与声道：48kHz 立体声 → 16kHz 单声道"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$A440" -ar 16000 -ac 1 \
  "$OUT/resample_mono_16k.wav"
show_output "$OUT/resample_mono_16k.wav"

printf '\n'
ok "课时 09 完成。下一步学习字幕的烧录与软字幕封装："
printf '%s\n' "  ./lessons/10-subtitles/run.sh"

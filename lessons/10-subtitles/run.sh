#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SOURCE_DIR/../../scripts/common.sh"

check_ffmpeg
require_samples
require_font
OUT="$(ensure_out 10-subtitles)"
IN="$SAMPLES_DIR/sample_h264_aac.mp4"
SRT="$SAMPLES_DIR/demo.srt"

print_banner "课时 10：字幕——烧录与软字幕"
info "视频：$IN"
info "字幕：$SRT"
info "输出目录：$OUT"

if [[ ! -f "$SRT" ]]; then
  fail "找不到 $SRT，请先运行 ./scripts/generate-samples.sh"
  exit 1
fi

info "1) 软字幕封装进 MKV（视频音频都 copy，字幕用 srt）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -i "$SRT" \
  -map 0 -map 1 \
  -c copy -c:s srt \
  -metadata:s:s:0 language=chi \
  "$OUT/soft_subs.mkv"
show_output "$OUT/soft_subs.mkv"

info "2) 软字幕封装进 MP4（字幕需转为 mov_text）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -i "$SRT" \
  -map 0 -map 1 \
  -c copy -c:s mov_text \
  -metadata:s:s:0 language=chi \
  "$OUT/soft_subs.mp4"
show_output "$OUT/soft_subs.mp4"
info "部分播放器对 MP4 里的 mov_text 支持不好；若看不到字，请改用 MKV 或烧录版本。"

info "3) 烧录字幕：把文字画进画面（必须重编码视频）"
if has_filter subtitles; then
  SRT_ESC="$(ffmpeg_escape "$SRT")"
  # 若找到了字体，把 fontsdir 指到该字体所在目录，提高中文命中率。
  STYLE_ARGS=""
  if [[ -n "${DEMO_FONT:-}" ]]; then
    FONT_DIR="$(dirname "$DEMO_FONT")"
    FONT_DIR_ESC="$(ffmpeg_escape "$FONT_DIR")"
    STYLE_ARGS=":fontsdir=${FONT_DIR_ESC}"
    if [[ "$DEMO_FONT_IS_CJK" != "yes" ]]; then
      warn "当前检测不到 CJK 字体，烧录出的中文可能是方框。软字幕不受影响，换播放器渲染即可。"
    fi
  fi
  run_cmd ffmpeg -hide_banner -loglevel warning -y \
    -i "$IN" \
    -vf "subtitles=${SRT_ESC}${STYLE_ARGS}" \
    -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
    -c:a copy \
    "$OUT/burned_in.mp4"
  show_output "$OUT/burned_in.mp4"
else
  warn "当前 FFmpeg 未启用 subtitles 滤镜（通常需要 libass），已跳过烧录。软字幕文件仍然可用。"
fi

printf '\n'
ok "课时 10 完成。最后一课讨论画质、速度和可选的苹果硬件加速："
printf '%s\n' "  ./lessons/11-quality/run.sh"

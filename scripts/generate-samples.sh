#!/usr/bin/env bash
# 用 FFmpeg lavfi 测试源生成学习用素材。可重复执行（会覆盖旧文件）。
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SOURCE_DIR/common.sh"

check_ffmpeg
mkdir -p "$SAMPLES_DIR"

print_banner "生成学习用示例素材"
info "输出目录：$SAMPLES_DIR"
info "全部由 lavfi 测试源生成，不含受版权保护的媒体，可放心重复运行。"

# ---------- 主示例：8 秒 1280x720 @ 30fps，H.264 + AAC ----------
# testsrc2 带有时间戳和色块，比纯色更适合观察裁剪、缩放、滤镜效果。
info "1/7  主视频 sample_h264_aac.mp4（8 秒，1280×720，30fps，H.264 + AAC）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "testsrc2=size=1280x720:rate=30:duration=8" \
  -f lavfi -i "sine=frequency=440:sample_rate=44100:duration=8" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p -g 30 -keyint_min 30 \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  "$SAMPLES_DIR/sample_h264_aac.mp4"
show_output "$SAMPLES_DIR/sample_h264_aac.mp4"

# ---------- SMPTE 彩条，4 秒 ----------
info "2/7  彩条视频 sample_bars.mp4（4 秒，带 880Hz 音调）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "smptebars=size=1280x720:rate=30:duration=4" \
  -f lavfi -i "sine=frequency=880:sample_rate=44100:duration=4" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a aac -b:a 96k \
  -movflags +faststart \
  "$SAMPLES_DIR/sample_bars.mp4"
show_output "$SAMPLES_DIR/sample_bars.mp4"

# ---------- 两段参数一致的短片，供拼接课使用 ----------
# 编码参数必须一致，concat demuxer 才能用 -c copy 无损拼接。
info "3/7  短片 clip_a.mp4（2 秒，testsrc 棋盘格）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "testsrc=size=1280x720:rate=30:duration=2" \
  -f lavfi -i "sine=frequency=520:sample_rate=44100:duration=2" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p -g 30 \
  -c:a aac -b:a 96k \
  -movflags +faststart \
  "$SAMPLES_DIR/clip_a.mp4"
show_output "$SAMPLES_DIR/clip_a.mp4"

info "4/7  短片 clip_b.mp4（2 秒，testsrc2，编码参数与 clip_a 相同）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "testsrc2=size=1280x720:rate=30:duration=2" \
  -f lavfi -i "sine=frequency=660:sample_rate=44100:duration=2" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p -g 30 \
  -c:a aac -b:a 96k \
  -movflags +faststart \
  "$SAMPLES_DIR/clip_b.mp4"
show_output "$SAMPLES_DIR/clip_b.mp4"

# ---------- 两路纯音频，供混音课使用 ----------
info "5/7  纯音频 tone_440.wav / tone_660.wav（各 6 秒，48kHz 立体声）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "sine=frequency=440:sample_rate=48000:duration=6" \
  -ac 2 \
  "$SAMPLES_DIR/tone_440.wav"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "sine=frequency=660:sample_rate=48000:duration=6" \
  -ac 2 \
  "$SAMPLES_DIR/tone_660.wav"
show_output "$SAMPLES_DIR/tone_440.wav"
show_output "$SAMPLES_DIR/tone_660.wav"

# ---------- 半透明水印图 ----------
info "6/7  水印图 logo.png（240×80，半透明蓝底）"
# 先画底色；若找到字体再叠一层文字。
require_font
LOGO_TMP="$SAMPLES_DIR/_logo_base.png"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "color=c=0x1A73E8@0.85:s=240x80:d=1,format=rgba" \
  -frames:v 1 \
  "$LOGO_TMP"

if [[ -n "${DEMO_FONT:-}" ]]; then
  FONT_ESC="$(ffmpeg_escape "$DEMO_FONT")"
  if [[ "$DEMO_FONT_IS_CJK" == "yes" ]]; then
    LOGO_TEXT="FFmpeg 学习"
  else
    LOGO_TEXT="FFmpeg"
  fi
  run_cmd ffmpeg -hide_banner -loglevel error -y \
    -i "$LOGO_TMP" \
    -vf "drawtext=fontfile=${FONT_ESC}:text='${LOGO_TEXT}':fontcolor=white:fontsize=28:x=(w-text_w)/2:y=(h-text_h)/2" \
    -frames:v 1 \
    "$SAMPLES_DIR/logo.png"
  rm -f "$LOGO_TMP"
else
  mv "$LOGO_TMP" "$SAMPLES_DIR/logo.png"
  warn "未找到字体，水印图只有纯色块，没有文字。"
fi
show_output "$SAMPLES_DIR/logo.png"

# ---------- UTF-8 字幕 ----------
info "7/7  演示字幕 demo.srt（UTF-8）"
cat > "$SAMPLES_DIR/demo.srt" <<'SRT'
1
00:00:00,000 --> 00:00:02,000
欢迎学习 FFmpeg

2
00:00:02,000 --> 00:00:04,500
这是一条软字幕示例

3
00:00:04,500 --> 00:00:07,000
可以烧录进画面，也可以单独封装

4
00:00:07,000 --> 00:00:08,000
课时 10 会用到本文件
SRT
ok "输出文件：$SAMPLES_DIR/demo.srt"

printf '\n'
ok "全部示例素材已就绪。接下来可以运行："
printf '%s\n' "  ./lessons/01-inspect/run.sh"
printf '%s\n' "  或一次性跑完全部课时：  ./run-all.sh"
printf '\n'

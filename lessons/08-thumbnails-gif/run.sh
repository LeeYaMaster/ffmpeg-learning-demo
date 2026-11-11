#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SOURCE_DIR/../../scripts/common.sh"

check_ffmpeg
require_samples
OUT="$(ensure_out 08-thumbnails-gif)"
IN="$SAMPLES_DIR/sample_h264_aac.mp4"
THUMBS="$OUT/thumbs"
mkdir -p "$THUMBS"

print_banner "课时 08：缩略图、逐秒截图与高质量 GIF"
info "输入：$IN"
info "输出目录：$OUT"

info "1) 从第 3 秒抽取一帧作为封面"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -ss 3 -i "$IN" -frames:v 1 \
  "$OUT/thumb_at_3s.jpg"
show_output "$OUT/thumb_at_3s.jpg"

info "2) 每秒一张截图，缩到宽 320，写入 thumbs/"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "fps=1,scale=320:-2" \
  "$THUMBS/img_%03d.png"
# 统计张数（兼容 Bash 3.2，不用 mapfile）
count=0
for f in "$THUMBS"/img_*.png; do
  [[ -f "$f" ]] || continue
  count=$((count + 1))
done
ok "共生成 ${count} 张截图，目录：$THUMBS"
# 展示第一张作为代表
show_output "$THUMBS/img_001.png"

info "3) 对比：不用调色板直接出 GIF（一般色带更明显）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "fps=8,scale=320:-2" \
  -c:v gif \
  "$OUT/naive.gif"
show_output "$OUT/naive.gif"

info "4) 高质量 GIF：先 palettegen，再 paletteuse"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -vf "fps=8,scale=320:-2:flags=lanczos,palettegen" \
  "$OUT/palette.png"
show_output "$OUT/palette.png"

run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" -i "$OUT/palette.png" \
  -lavfi "fps=8,scale=320:-2:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer" \
  "$OUT/palette.gif"
show_output "$OUT/palette.gif"

info "5) 一条命令用 split 完成同样的高质量 GIF"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -filter_complex "fps=8,scale=320:-2:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse=dither=bayer" \
  "$OUT/palette_onepass.gif"
show_output "$OUT/palette_onepass.gif"

printf '\n'
ok "课时 08 完成。建议对比 naive.gif 与 palette.gif，然后进入音频处理："
printf '%s\n' "  ./lessons/09-audio/run.sh"

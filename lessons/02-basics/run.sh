#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SOURCE_DIR/../../scripts/common.sh"

check_ffmpeg
require_samples
OUT="$(ensure_out 02-basics)"

print_banner "课时 02：输入 / 输出基本规则（-i、-y、-map、lavfi）"
info "输出目录：$OUT"

info "1) 用 lavfi 现场生成 3 秒彩条 + 静音（注意 -shortest：anullsrc 默认无限长）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "smptebars=size=640x360:rate=25:duration=3" \
  -f lavfi -i "anullsrc=r=44100:cl=stereo" \
  -shortest \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p \
  -c:a aac -b:a 64k \
  "$OUT/from_lavfi.mp4"
show_output "$OUT/from_lavfi.mp4"

info "2) 不写 -map：FFmpeg 按默认规则各选一路视频、一路音频（这里输入只有这两路，结果很直观）"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$SAMPLES_DIR/sample_h264_aac.mp4" \
  -c copy \
  "$OUT/default_map_copy.mp4"
show_output "$OUT/default_map_copy.mp4"

info "3) 显式 -map：视频来自主示例，音频来自彩条文件，重新编码音频并按较短的那路截断"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$SAMPLES_DIR/sample_h264_aac.mp4" \
  -i "$SAMPLES_DIR/sample_bars.mp4" \
  -map 0:v:0 -map 1:a:0 \
  -c:v copy -c:a aac -b:a 96k \
  -shortest \
  "$OUT/remap_audio.mp4"
show_output "$OUT/remap_audio.mp4"
info "这条片子画面是 testsrc2（8 秒源），声音是 880Hz（4 秒源），被 -shortest 截成约 4 秒。"

info "4) -map 只保留视频，并加上 -an，得到无音轨文件"
run_cmd ffmpeg -hide_banner -loglevel error -y \
  -i "$SAMPLES_DIR/sample_h264_aac.mp4" \
  -map 0:v:0 -an -c:v copy \
  "$OUT/video_only.mp4"
show_output "$OUT/video_only.mp4"

info "5) 演示 -n：文件已存在时拒绝覆盖"
printf '\n%s\n' "${C_CYAN}将执行：${C_RESET}"
printf '%s\n' "  ffmpeg -n -i ... $OUT/from_lavfi.mp4"
printf '%s\n' "${C_DIM}───${C_RESET}"
# 注意：部分 FFmpeg 版本在 -n 拒绝覆盖时仍然返回退出码 0，
# 所以这里同时检查终端提示，而不是只看 $? 。
set +e
n_msg="$(ffmpeg -hide_banner -loglevel error -n   -f lavfi -i "color=c=red:s=320x240:d=1"   -f lavfi -i "anullsrc=r=44100:cl=mono"   -shortest -c:v libx264 -pix_fmt yuv420p -c:a aac   "$OUT/from_lavfi.mp4" 2>&1)"
n_status=$?
set -e
printf '%s\n' "$n_msg"
if printf '%s' "$n_msg" | grep -q "already exists"; then
  ok "如预期：加了 -n 且目标已存在，FFmpeg 拒绝覆盖并提示 already exists（本机退出码 $n_status，部分版本此处为 0，不要只靠退出码判断）。"
  info "脚本里反复练习时请继续用 -y。"
else
  warn "没有看到 already exists 提示（退出码 $n_status）。若你事先删除过目标文件，就不会触发覆盖保护。"
fi

printf '\n'
ok "课时 02 完成。下一步学习转码与封装拷贝："
printf '%s\n' "  ./lessons/03-transcode/run.sh"

#!/usr/bin/env bash
# 供各课时脚本 source 的公共函数。不要直接执行本文件。
# 兼容 macOS 自带的 Bash 3.2 与 Homebrew Bash 5。

# 若被直接执行，给出提示后退出。
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf '%s\n' "这是公共函数库，请不要直接运行。请执行各课时的 run.sh，或先运行 ./scripts/generate-samples.sh"
  exit 1
fi

# 父脚本可能已经设置过；再设一次是安全的。
set -euo pipefail

_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$_COMMON_DIR/.." && pwd)"
SAMPLES_DIR="$PROJECT_ROOT/samples"
OUTPUT_DIR="$PROJECT_ROOT/output"

# 终端彩色输出（非 TTY 时自动关闭）
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_CYAN=$'\033[36m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
else
  C_RESET=""
  C_BOLD=""
  C_DIM=""
  C_CYAN=""
  C_GREEN=""
  C_YELLOW=""
  C_RED=""
fi

info()  { printf '%s\n' "${C_CYAN}▸${C_RESET} $*"; }
ok()    { printf '%s\n' "${C_GREEN}✓${C_RESET} $*"; }
warn()  { printf '%s\n' "${C_YELLOW}!${C_RESET} $*"; }
fail()  { printf '%s\n' "${C_RED}✗${C_RESET} $*" >&2; }

# 打印安装提示后以给定退出码结束。
_install_hint() {
  local tool="$1"
  fail "未找到 ${tool}，请先安装 FFmpeg 后再运行。"
  cat >&2 <<'HINT'

  macOS（推荐 Homebrew）：
    brew install ffmpeg

  Debian / Ubuntu：
    sudo apt update && sudo apt install -y ffmpeg

  安装完成后请确认三个命令都能运行：
    ffmpeg  -version
    ffprobe -version
    ffplay  -version

HINT
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    _install_hint "$cmd"
    exit 1
  fi
}

# 检查 ffmpeg / ffprobe。ffplay 用于预览，缺失时只警告（无显示器的环境常见）。
check_ffmpeg() {
  require_cmd ffmpeg
  require_cmd ffprobe
  if ! command -v ffplay >/dev/null 2>&1; then
    warn "未找到 ffplay。课时脚本不依赖它，但本地预览时会用到；macOS 上 brew install ffmpeg 一般会带上。"
  fi
}

# 编码器是否可用（名字需与 `ffmpeg -encoders` 中的标识一致）。
# 先把完整列表读入变量再 grep：grep -q 会提前关闭管道，
# 在 set -o pipefail 下直接管道会得到 141（SIGPIPE），误判为「没有该编码器」。
has_encoder() {
  local name="$1"
  local list
  list="$(ffmpeg -hide_banner -encoders 2>&1)" || true
  printf '%s
' "$list" | grep -qE "[[:space:]]${name}[[:space:]]"
}

has_filter() {
  local name="$1"
  local list
  list="$(ffmpeg -hide_banner -filters 2>&1)" || true
  printf '%s
' "$list" | grep -qE "[[:space:]]${name}[[:space:]]"
}

# 把路径转义成可放进 -vf / -filter_complex 选项值的形式。
ffmpeg_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\'/\\\'}"
  s="${s//:/\\:}"
  s="${s//\[/\\[}"
  s="${s//\]/\\]}"
  printf '%s' "$s"
}

# 查找一块可用于 drawtext 的字体。优先 CJK，找不到再退回拉丁字体。
# 结果写入全局变量：DEMO_FONT、DEMO_FONT_IS_CJK（yes/no）、DEMO_FONT_LABEL
find_font() {
  DEMO_FONT=""
  DEMO_FONT_IS_CJK="no"
  DEMO_FONT_LABEL=""

  local cjk_candidates="
/System/Library/Fonts/PingFang.ttc
/System/Library/Fonts/STHeiti Light.ttc
/System/Library/Fonts/STHeiti Medium.ttc
/System/Library/Fonts/Hiragino Sans GB.ttc
/System/Library/Fonts/Supplemental/Songti.ttc
/System/Library/Fonts/Supplemental/Arial Unicode.ttf
/Library/Fonts/Arial Unicode.ttf
/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc
/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc
/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc
/usr/share/fonts/truetype/wqy/wqy-microhei.ttc
/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf
"

  local latin_candidates="
/System/Library/Fonts/Supplemental/Arial.ttf
/System/Library/Fonts/Supplemental/Times New Roman.ttf
/Library/Fonts/Arial.ttf
/System/Library/Fonts/Helvetica.ttc
/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf
/usr/share/fonts/truetype/freefont/FreeSans.ttf
"

  local path
  # 用换行拆分，避免 Bash 3.2 没有 mapfile，也避免路径中的空格被 IFS 拆开。
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if [[ -f "$path" ]]; then
      DEMO_FONT="$path"
      DEMO_FONT_IS_CJK="yes"
      DEMO_FONT_LABEL="CJK 字体：$path"
      return 0
    fi
  done <<EOF
$cjk_candidates
EOF

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if [[ -f "$path" ]]; then
      DEMO_FONT="$path"
      DEMO_FONT_IS_CJK="no"
      DEMO_FONT_LABEL="拉丁字体（未找到 CJK 字体，中文可能显示为方框）：$path"
      return 0
    fi
  done <<EOF
$latin_candidates
EOF

  return 1
}

require_font() {
  if find_font; then
    info "$DEMO_FONT_LABEL"
    if [[ "$DEMO_FONT_IS_CJK" != "yes" ]]; then
      warn "当前字体不含完整中文字形，drawtext / 字幕里的汉字可能显示为方框。可安装 Noto Sans CJK 或在 macOS 上确认系统字体未被删除。"
    fi
  else
    warn "未找到可用字体文件。需要绘制文字的步骤会被跳过，其余步骤照常进行。"
    DEMO_FONT=""
    DEMO_FONT_IS_CJK="no"
    DEMO_FONT_LABEL="（无字体）"
  fi
}

require_samples() {
  local needed="$SAMPLES_DIR/sample_h264_aac.mp4"
  if [[ ! -f "$needed" ]]; then
    fail "还没有示例素材：$needed"
    printf '%s\n' "请先在项目根目录运行：  ./scripts/generate-samples.sh" >&2
    exit 1
  fi
}

# 课时输出目录：output/<课时目录名>/
lesson_out_dir() {
  local lesson_dir
  lesson_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  local name
  name="$(basename "$lesson_dir")"
  local dest="$OUTPUT_DIR/$name"
  mkdir -p "$dest"
  printf '%s' "$dest"
}

# 兼容从 run.sh 里直接调用：传入课时目录名。
ensure_out() {
  local name="$1"
  local dest="$OUTPUT_DIR/$name"
  mkdir -p "$dest"
  printf '%s' "$dest"
}

print_banner() {
  local title="$1"
  printf '\n%s\n' "${C_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  printf '%s\n' "${C_BOLD}  $title${C_RESET}"
  printf '%s\n' "${C_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
}

# 以可复制的形式打印命令，然后执行。参数按 argv 传递，避免二次解析。
run_cmd() {
  local pretty=""
  local arg
  for arg in "$@"; do
    pretty="$pretty $(printf '%q' "$arg")"
  done
  printf '\n%s\n' "${C_CYAN}将执行：${C_RESET}"
  printf '%s\n' "  ${pretty# }"
  printf '%s\n' "${C_DIM}───${C_RESET}"
  "$@"
}

# 打印输出文件，并可选地用 ffprobe 给一行摘要。
show_output() {
  local file="$1"
  if [[ ! -e "$file" ]]; then
    fail "预期的输出不存在：$file"
    return 1
  fi
  ok "输出文件：$file"
  if command -v ffprobe >/dev/null 2>&1; then
    # 图片、字幕等没有 duration 也没关系，失败时忽略。
    ffprobe -hide_banner -v error \
      -show_entries format=format_name,duration,size,bit_rate \
      -show_entries stream=index,codec_type,codec_name,width,height,sample_rate,channels \
      -of default=noprint_wrappers=0 \
      "$file" 2>/dev/null | sed 's/^/    /' || true
  fi
}

# 安静模式探测一条命令是否能成功（用于“预期会失败”的演示，或可选编码器）。
# 不使用 GNU timeout，以便在 macOS 上也能跑。
cmd_exists_silent() {
  command -v "$1" >/dev/null 2>&1
}

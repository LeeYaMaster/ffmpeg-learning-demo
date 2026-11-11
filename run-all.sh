#!/usr/bin/env bash
# 生成示例素材，并按 01–11 的顺序跑完全部课时。
# 用法：
#   ./run-all.sh              # 先生成（或覆盖）素材，再跑全部课时
#   ./run-all.sh --skip-samples
#   ./run-all.sh --only 03    # 只跑编号匹配的课时（仍默认先生成素材）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# shellcheck source=scripts/common.sh
source "$ROOT/scripts/common.sh"

check_ffmpeg

SKIP_SAMPLES=0
ONLY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-samples)
      SKIP_SAMPLES=1
      shift
      ;;
    --only)
      if [[ $# -lt 2 ]]; then
        fail "请为 --only 提供课时编号，例如：./run-all.sh --only 05"
        exit 2
      fi
      ONLY="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'USAGE'
用法：./run-all.sh [选项]

  --skip-samples   跳过素材生成（需已经跑过 ./scripts/generate-samples.sh）
  --only 03        只运行目录名以该编号开头的课时
  -h, --help       显示本说明

缺少 ffmpeg / ffprobe 时会打印安装提示并以非 0 退出。
USAGE
      exit 0
      ;;
    *)
      fail "未知参数：$1  （可用 --help 查看用法）"
      exit 2
      ;;
  esac
done

print_banner "FFmpeg 学习 Demo：按顺序运行"

if [[ "$SKIP_SAMPLES" -eq 0 ]]; then
  "$ROOT/scripts/generate-samples.sh"
else
  info "已跳过素材生成。"
  require_samples
fi

LESSONS=""
for dir in "$ROOT"/lessons/[0-9][0-9]-*; do
  [[ -d "$dir" ]] || continue
  [[ -x "$dir/run.sh" || -f "$dir/run.sh" ]] || continue
  name="$(basename "$dir")"
  if [[ -n "$ONLY" ]]; then
    case "$name" in
      "$ONLY"-*|0"$ONLY"-*|"$ONLY")
        ;;
      *)
        continue
        ;;
    esac
  fi
  LESSONS="$LESSONS $name"
done

if [[ -z "${LESSONS// /}" ]]; then
  fail "没有找到要运行的课时。请检查 lessons/ 目录，或 --only 的编号。"
  exit 1
fi

info "将运行的课时：$LESSONS"
failed=""
passed=0
total=0

for name in $LESSONS; do
  total=$((total + 1))
  script="$ROOT/lessons/$name/run.sh"
  if [[ ! -x "$script" ]]; then
    chmod +x "$script" 2>/dev/null || true
  fi
  printf '\n%s\n' "${C_BOLD}▶ 开始 $name${C_RESET}"
  set +e
  "$script"
  status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    passed=$((passed + 1))
    ok "$name 完成"
  else
    failed="$failed $name"
    fail "$name 失败（退出码 $status）。已停止后续课时，方便你先查看报错。"
    break
  fi
done

printf '\n'
print_banner "运行结果"
info "成功：$passed / $total"
if [[ -n "${failed// /}" ]]; then
  fail "失败的课时：$failed"
  exit 1
fi
ok "全部选定课时已成功完成。输出位于：$OUTPUT_DIR"
info "常用命令碎片和易错点见 CHEATSHEET.md"
exit 0

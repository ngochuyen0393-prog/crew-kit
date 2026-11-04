#!/usr/bin/env bash
# validate-ready.sh — READY 块机械验证器（crew-kit 通用版）
# 用法: validate-ready.sh <ready文件路径> [项目盘目录]
#   项目盘缺省: 环境变量 CREW_DRIVE → 再缺省当前目录（须含 CREW.md）
# 参数来源: 项目盘 CREW.md 参数表的 REPO_PATH / BASE / CHECK_NAMES 三行
# 退出码: 0 = READY-VALID；1 = READY-REJECT（原因逐行打印）
# 原则：只信 git 事实与固定字段，不信泳道的散文。

set -u
READY_FILE="${1:?用法: validate-ready.sh <ready文件> [项目盘目录]}"
DRIVE="${2:-${CREW_DRIVE:-$PWD}}"
[ -f "$DRIVE/CREW.md" ] || DRIVE="$(cd "$(dirname "$0")/.." && pwd)"      # bin/ 的上一级（盘根）
[ -f "$DRIVE/CREW.md" ] || { echo "READY-REJECT 找不到项目盘 CREW.md（试过: $DRIVE）"; exit 1; }
CREW="$DRIVE/CREW.md"
REJECTS=()

# --- 从 CREW.md 参数表读参数（| `KEY` | value | 行）---
crew_param() {
  grep -m1 -E "^\|[[:space:]]*\`$1\`[[:space:]]*\|" "$CREW" \
    | awk -F'|' '{print $3}' | sed 's/`//g; s/^[[:space:]]*//; s/[[:space:]]*$//'
}
REPO_PATH="$(crew_param REPO_PATH)"
BASE="$(crew_param BASE)"
CHECK_NAMES="$(crew_param CHECK_NAMES)"

[ -n "$REPO_PATH" ] || REJECTS+=("CREW.md 缺 REPO_PATH 参数行")
[ -n "$BASE" ] || REJECTS+=("CREW.md 缺 BASE 参数行")
[ -d "$REPO_PATH" ] || REJECTS+=("REPO_PATH 目录不存在: $REPO_PATH")

# --- 读取 READY 文件（显式剥 ，防 CRLF 在非 gawk 环境误判）---
[ -f "$READY_FILE" ] || { echo "READY-REJECT 文件不存在: $READY_FILE"; exit 1; }
READY_NORM="$(mktemp)"
trap 'rm -f "$READY_NORM"' EXIT
tr -d '' < "$READY_FILE" > "$READY_NORM"
READY_FILE="$READY_NORM"
READY_HEAD_LINE="$(grep -m1 '^READY ' "$READY_FILE")"
[ -n "$READY_HEAD_LINE" ] || { echo "READY-REJECT 缺少首行 'READY <branch> <sha40>'"; exit 1; }

BRANCH="$(awk '{print $2}' <<<"$READY_HEAD_LINE")"
SHA="$(awk '{print $3}' <<<"$READY_HEAD_LINE")"

# --- 字段格式 ---
[[ "$BRANCH" =~ ^[A-Za-z0-9/._-]+$ ]] || REJECTS+=("分支名含非法字符: $BRANCH")
[ -n "$BASE" ] && [ "$BRANCH" = "$BASE" ] && REJECTS+=("交单分支不得是 BASE（$BASE 自身无可合并内容）")
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || REJECTS+=("头 SHA 不是 40 位十六进制: '$SHA'")

PIN="$(grep -m1 '^pin:' "$READY_FILE" | awk '{print $2}')"
[ "$PIN" = "$SHA" ] || REJECTS+=("pin 与 READY 行头不一致: pin='$PIN' head='$SHA'")

BASE_LINE="$(grep -m1 "^base:" "$READY_FILE")"
[[ "$BASE_LINE" =~ ^base:[[:space:]]+(.+)\@[0-9a-f]{12,40}$ ]] || REJECTS+=("base 行格式错（应 base: <BASE>@<sha12+>）: '$BASE_LINE'")
STATED_BASE="$(sed -E 's/^base:[[:space:]]+([^@]+)@.*/\1/' <<<"$BASE_LINE")"
[ "$STATED_BASE" = "$BASE" ] || REJECTS+=("base 分支 ≠ CREW.md 的 BASE: stated=$STATED_BASE crew=$BASE")

TREE_STATED="$(grep -m1 '^tree:' "$READY_FILE" | awk '{print $2}')"

CHECKS_LINE="$(grep -m1 '^checks:' "$READY_FILE")"
if [ -z "$CHECK_NAMES" ]; then
  REJECTS+=("CREW.md 缺 CHECK_NAMES 参数行（逗号分隔的必需检查名）")
else
  OLDIFS="$IFS"; IFS=','
  for NAME in $CHECK_NAMES; do
    NAME="$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<<"$NAME")"
    [ -n "$NAME" ] || continue
    grep -qE "(^|[[:space:]])${NAME}=green([[:space:]]|$)" <<<"$CHECKS_LINE" \
      || REJECTS+=("checks 缺 $NAME=green（或非绿）: '$CHECKS_LINE'")
  done
  IFS="$OLDIFS"
fi

grep -m1 -q '^test-count:' "$READY_FILE" || REJECTS+=("缺少 test-count: 行（通过数/失败数）")
grep -m1 -q '^review passes:' "$READY_FILE" || REJECTS+=("缺少 review passes: 行（审查轮次）")

grep -qi '^Head frozen from now on' "$READY_FILE" || REJECTS+=("缺少头冻结声明行")

FLAKY_LINE="$(grep -m1 '^flaky:' "$READY_FILE")"

# --- git 事实核验（不信散文，只信仓库）---
GIT() { git -C "$REPO_PATH" "$@"; }

if [ -d "$REPO_PATH" ] && GIT rev-parse --verify --quiet "$BRANCH^{commit}" >/dev/null 2>&1; then
  TIP="$(GIT rev-parse "$BRANCH")"
  [ "$TIP" = "$SHA" ] || REJECTS+=("分支尖端 ≠ 声明头: tip=${TIP:0:12} stated=${SHA:0:12}（冻结后是否又 push 了？）")
  ACTUAL_TREE="$(GIT rev-parse "$BRANCH^{tree}")"
  [ "$TREE_STATED" = "$ACTUAL_TREE" ] || REJECTS+=("树哈希对不上: stated=${TREE_STATED:0:12} actual=${ACTUAL_TREE:0:12}")
  if [ -n "$BASE" ] && GIT rev-parse --verify --quiet "$BASE" >/dev/null 2>&1; then
    BASE_TIP="$(GIT rev-parse "$BASE")"
    STATED_BASE_SHA="$(sed -E 's/^base:[[:space:]]+[^@]+@//' <<<"$BASE_LINE")"
    [ "${STATED_BASE_SHA:0:12}" = "${BASE_TIP:0:12}" ] \
      || REJECTS+=("base 与 $BASE 当前尖端漂移: stated=${STATED_BASE_SHA:0:12} ${BASE}=${BASE_TIP:0:12}（重交前先并最新 $BASE）")
  fi
else
  [ -d "$REPO_PATH" ] && REJECTS+=("仓库里不存在分支: $BRANCH")
fi

# --- flaky 台账核验 ---
if [ -n "$FLAKY_LINE" ] && ! grep -q '^flaky: none' <<<"$FLAKY_LINE"; then
  CASE="$(sed 's/^flaky: //' <<<"$FLAKY_LINE" | cut -d, -f1)"
  LEDGER="$DRIVE/handoffs/flaky-ledger.md"
  [ -f "$LEDGER" ] && grep -qF "$CASE" "$LEDGER" || REJECTS+=("flaky 用例 '$CASE' 未登记台账 handoffs/flaky-ledger.md")
fi

# --- 裁决 ---
if [ ${#REJECTS[@]} -gt 0 ]; then
  printf 'READY-REJECT %s\n' "${REJECTS[@]}"
  exit 1
fi
echo "READY-VALID $BRANCH ${SHA:0:12}"
exit 0

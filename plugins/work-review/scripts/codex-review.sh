#!/usr/bin/env bash
# Codex를 검증 담당으로 실행한다. 읽기 전용 샌드박스라 Codex는 파일을 고칠 수 없다.
#
#   codex-review.sh [CODEX_MODEL] <<'MSG'
#   TASK: ...
#   MSG
#
# 검증 지시문은 agents/reviewer.md 본문을 그대로 쓴다 (Claude 검증 담당과 같은 기준).
# 종료 코드: 0 = 검토 결과 출력, 3 = codex 명령 없음, 4 = codex 실행 실패
set -euo pipefail

model=${1:-}
here=$(cd "$(dirname "$0")" && pwd)

if ! command -v codex >/dev/null 2>&1; then
  echo "ERROR: codex 명령을 찾을 수 없습니다. 'npm install -g @openai/codex' 후 'codex login'을 실행하세요." >&2
  exit 3
fi

root=$(git rev-parse --show-toplevel)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# reviewer.md의 frontmatter(--- 사이)를 뺀 본문 + 이번 검토 요청
{
  awk 'f >= 2 { print } /^---$/ { f++ }' "$here/../agents/reviewer.md"
  printf '\n---\n\n'
  cat
} > "$tmp/prompt.md"

args=(exec -s read-only --ephemeral -C "$root" -o "$tmp/last.txt")
if [ -n "$model" ]; then
  args+=(-m "$model")
fi

if ! PYTHONDONTWRITEBYTECODE=1 codex "${args[@]}" - < "$tmp/prompt.md" > "$tmp/log" 2>&1; then
  echo "ERROR: codex exec 실패" >&2
  tail -20 "$tmp/log" >&2
  exit 4
fi

cat "$tmp/last.txt"

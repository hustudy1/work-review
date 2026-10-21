# work-review

Claude Code에서 **작업 담당과 검증 담당을 나눠 쓰는** 플러그인이다.
명령 하나로 작업 → 검증 → 수정 → 재검증이 끝까지 돈다.

```
/work-review:run 상품 가격에 할인율을 적용하는 함수 추가해줘
```

| 역할 | 누가 | 하는 일 |
|------|------|---------|
| 작업 담당 | 지금 쓰는 대화의 모델 (예: Opus) | 작업하고, 테스트하고, 지적받은 것을 고친다 |
| 검증 담당 | 별도 에이전트 (기본 Sonnet, `REVIEWER=`로 Opus·Haiku·Codex로 변경) | 변경(diff)만 보고 검토한다. **파일을 고칠 수 없다** |

검증 담당은 작업 과정을 보지 못한 채 새로 시작한다. 그래서 작업 담당이 스스로 확신하게 된
실수를 그대로 따라가지 않는다.

## 설치

**터미널**에서 아래 두 줄을 실행한다. Claude Code가 GitHub에서 플러그인을 받아 `~/.claude/plugins/`에 설치한다.
저장소를 clone할 필요는 없다.

```bash
claude plugin marketplace add hustudy1/work-review
claude plugin install work-review@work-review
```

터미널에서 Claude Code를 쓰는 중이라면 채팅창에서 `/plugin marketplace add hustudy1/work-review`,
`/plugin install work-review@work-review`로 해도 된다. **VS Code 확장의 채팅창에서는 `/plugin` 명령을 쓸 수 없으므로**
위의 터미널 명령을 쓴다. VS Code 확장은 터미널 Claude Code와 같은 설치 위치(`~/.claude/`)를 쓰므로,
터미널에서 설치하면 VS Code에서도 바로 쓸 수 있다. 설치 후 VS Code 창(또는 Claude Code)을 다시 연다.

| 할 일 | 명령 |
|------|------|
| 새 버전 받기 | `claude plugin update work-review@work-review` |
| 삭제 | `claude plugin uninstall work-review@work-review` |

## 사용법

| 명령 | 하는 일 |
|------|---------|
| `/work-review:run <작업>` | 작업 → 검증 → 수정 → 재검증 (기본 최대 3라운드) |
| `/work-review:run MAX_ROUNDS=5 <작업>` | 라운드 수를 바꿔서 실행 (1~5) |
| `/work-review:run REVIEWER=opus <작업>` | 검증 담당을 바꿔서 실행 (아래 "모델 고르기") |
| `/work-review:check [의도]` | 이미 바꿔 둔 내용을 검증만 한다. 아무것도 고치지 않는다 |

설정(`REVIEWER=`, `CODEX_MODEL=`, `MAX_ROUNDS=`)은 작업 설명보다 앞에 쓰고, 순서는 상관없다.

## 모델 고르기

| 역할 | 정하는 법 | 기본값 |
|------|-----------|--------|
| 작업 담당 | 지금 대화의 모델이 그대로 작업한다. VS Code 채팅창의 모델 선택이나 `/model`로 바꾼다 | 대화에서 고른 모델 |
| 검증 담당 | 명령에 `REVIEWER=sonnet`, `opus`, `haiku`, `codex` 중 하나를 붙인다 | `sonnet` |

```
/work-review:run 할인 함수 추가해줘                     ← 검증 담당 Sonnet
/work-review:run REVIEWER=opus 결제 로직 수정해줘        ← 중요한 작업은 더 강한 모델로 검증
/work-review:check REVIEWER=haiku                       ← 가벼운 확인은 싼 모델로
/work-review:run REVIEWER=codex 할인 함수 추가해줘        ← OpenAI Codex가 검증 (아래 "Codex로 검증하기")
```

| 목적 | 작업 담당 (대화 모델) | 검증 담당 |
|------|------|------|
| 평소 | Sonnet | Sonnet (기본값) |
| 중요한 작업 | Sonnet | `REVIEWER=opus` |
| 어려운 작업 | Opus | Sonnet (기본값) |

작업 담당과 검증 담당이 같은 모델이어도 검증은 의미가 있다. 검증 담당은 작업 과정을 모른 채 새로 시작해서
diff와 규칙만 보고 판단한다. 다만 같은 모델은 비슷한 실수를 놓칠 수 있어서, 중요한 작업에는 다른 모델을 권한다.

결과는 이 중 하나로 끝난다.

| 결과 | 의미 |
|------|------|
| n라운드에서 통과 | 검증 담당이 PASS를 냈다 |
| 결정 필요 | 요청이 프로젝트 규칙과 충돌한다. 규칙과 두 가지 선택지를 보여 주고 멈춘다 |
| n라운드 후 미통과 | 라운드가 끝날 때까지 지적이 남았다. 남은 지적을 보여 준다 |

**커밋, push, 배포는 하지 않는다.** 끝나면 변경 파일과 권장 커밋 메시지를 알려 준다.

## 프로젝트 규칙 알려 주기: REVIEW.md

프로젝트 루트에 `REVIEW.md`를 두면 검증 담당이 가장 먼저 읽는다.
양식은 [plugins/work-review/templates/REVIEW.md](plugins/work-review/templates/REVIEW.md)에 있다.

- **테스트 명령**: 검증 담당이 실제로 실행한다
- **절대 하지 말 것**: 위반하면 사용자가 시킨 일이라도 high로 보고한다
- **꼭 확인할 것**: 이 프로젝트에서 자주 틀리는 곳

`REVIEW.md`가 없으면 `AGENTS.md`, `CLAUDE.md`의 규칙과 기본 점검 항목(요청 범위, 정확성, 테스트, 비밀값)으로 검토한다.

## 검증 담당이 보는 것

1. 요청한 일을 빠짐없이 했는가, 요청하지 않은 것을 덧붙이지 않았는가
2. 프로젝트 규칙("절대 하지 말 것")을 어기지 않았는가
3. 경계값, 오류 경로, 빈 입력에서 틀리지 않는가
4. 테스트를 실제로 실행하고, 그 테스트가 새 동작을 정말 검사하는가
5. API 키, 토큰, 개인 경로, 이메일이 섞이지 않았는가 (값은 출력하지 않는다)

지적에는 반드시 `파일:줄`과 틀리는 상황이 붙는다. 근거 없는 지적과 취향 지적은 하지 않는다.

## Codex로 검증하기

`REVIEWER=codex`를 붙이면 Claude가 작업하고 **OpenAI Codex가 검증**한다. 회사가 다른 모델이라 같은 실수를 공유할 가능성이 낮다.

```
/work-review:run REVIEWER=codex 할인 함수 추가해줘
/work-review:run REVIEWER=codex CODEX_MODEL=gpt-6-luna 할인 함수 추가해줘   ← Codex 모델 지정
```

**준비물**: 터미널에서 `codex` 명령이 실행돼야 한다 (`codex --version`으로 확인).

```bash
npm install -g @openai/codex
codex login        # VS Code의 Codex 확장에서 이미 로그인했다면 생략 (로그인 정보를 같이 쓴다)
```

VS Code의 Codex 확장만 설치한 상태로는 안 된다. 확장 안의 codex는 터미널 경로(PATH)에 없어서 Claude Code가 부를 수 없다.

동작 방식:
- 검증 지시문은 Claude 검증 담당과 같은 `agents/reviewer.md`를 쓴다
- Codex는 `codex exec --sandbox read-only`로 실행되어 **파일을 쓸 수 없다**
- `CODEX_MODEL`을 생략하면 Codex 설정(`~/.codex/config.toml`)의 기본 모델을 쓴다. 쓸 수 있는 모델은 ChatGPT 요금제에 따라 다르다
- 비용은 ChatGPT 요금제 사용량(또는 API 키 요금)에서 나간다

**권장**: 주 검증 담당은 Claude(Sonnet 이상)로 두고, Codex는 중요한 작업에서 두 번째 의견으로 쓴다.
2026-10-21 시험에서 `gpt-6-luna`는 문제 3개를 잡아낸 적도 있지만, 다른 실행에서는 1개를 놓치고 실패 예시를 틀리게 든 적도 있다.

Codex 채팅창에서 직접 검토를 맡겨도 된다:

> `REVIEW.md 기준으로 git diff를 검토해줘. 파일은 고치지 말고 VERDICT: PASS 또는 CHANGES_REQUESTED와 근거(파일:줄)로 답해줘.`

## 비용

설치만 해 두면 평소 대화에는 약 235토큰(스킬·에이전트 설명)만 붙는다. 실행하면 검증 1라운드마다 두 가지가 더 든다.

- 검증 담당(Sonnet): diff, REVIEW.md, 테스트 결과만 읽는다. 아래 시험에서 라운드당 $0.02~0.05
- 작업 담당의 추가 턴 1번: 검증을 맡기고 결과를 읽는 턴. 아래 시험에서 약 $0.05

작은 작업에서는 1라운드에 작업 비용의 약 20~30%가 더 든다(추정, 플러그인 없는 실행과의 비교 측정은 아직 없음).
추가 턴은 라운드당 1번이라 큰 작업일수록 비율이 낮아지고, diff가 클수록 검증 담당이 읽는 양은 늘어난다.

| 시험 (2026-10-21, 작은 Python 프로젝트) | 라운드 | 전체 비용 | 그중 검증 담당 |
|------|------|------|------|
| `check`: 일부러 넣은 문제 3개 검출 | 1 | $0.41 | $0.04 |
| `run`: 첫 라운드 통과 | 1 | $0.27 | $0.02 |
| `run`: 수정 후 2라운드 통과 | 2 | $0.35 | $0.05 |
| `run`: 규칙과 충돌 → 결정 요청 | 1 | $0.25 | $0.03 |

실제 비용은 프로젝트 크기와 변경량에 따라 달라진다.

## 한계

- 검증 담당의 "파일을 고치지 않는다"는 도구 제한(Edit/Write 없음)과 지시로 지킨다.
  Bash는 테스트 실행에 필요해서 열려 있으므로, 완전한 차단은 아니다.
- git 저장소에서만 동작한다 (diff를 기준으로 검토한다).
- `REVIEWER=codex`는 bash 스크립트로 Codex를 부른다. macOS·Linux에서 시험했고, Windows는 Git Bash나 WSL이 필요하다(미검증).
- 검증 담당도 모델이라 놓칠 수 있다. 통과는 "검토에서 문제를 찾지 못했다"는 뜻이지 정답 보증이 아니다.

## 구성

```
.claude-plugin/marketplace.json        마켓플레이스 정의
plugins/work-review/
├── .claude-plugin/plugin.json         플러그인 정의
├── skills/run/SKILL.md                /work-review:run — 작업과 검증 라운드 진행
├── skills/check/SKILL.md              /work-review:check — 검증만
├── agents/reviewer.md                 검증 담당 (기본 Sonnet, 읽기·테스트 실행만)
├── scripts/codex-review.sh            REVIEWER=codex일 때 Codex를 읽기 전용으로 실행
└── templates/REVIEW.md                프로젝트 점검 항목 양식
```

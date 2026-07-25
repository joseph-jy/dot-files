---
title: Git 커밋과 PR
description: magit으로 stage/commit, forge로 GitHub Enterprise PR 확인
---

**상황**: 수정을 마쳤다. 변경분을 검토하고 커밋한 뒤, PR 리뷰 코멘트를 확인하고 싶다.

## 1. Magit status — 모든 것의 시작

```
C-x g
```

status 버퍼가 뜬다. **커서를 항목에 올리고 한 글자 키**로 조작하는 방식이다.

| 키 | 동작 |
|---|---|
| `TAB` | 파일/섹션 접기·펼치기 (diff 미리보기) |
| `s` | stage (파일 전체 또는 커서가 있는 hunk만) |
| `u` | unstage |
| `k` | 변경 버리기 (discard — 주의) |
| `c c` | commit — 메시지 작성 후 `C-c C-c`로 확정, `C-c C-k`로 취소 |
| `c a` | commit amend |
| `P p` | push |
| `F p` | pull |
| `b b` | 브랜치 전환 |
| `g` | status 새로고침 |
| `q` | 닫기 |

### hunk 단위 stage — magit의 최대 강점

1. `C-x g` → 변경 파일에서 `TAB`으로 diff 펼침
2. 원하는 hunk에 커서를 두고 `s` — 그 hunk만 stage
3. 더 잘게 쪼개려면 영역을 `C-SPC`로 선택하고 `s` — **선택한 줄만** stage

AI agent가 만든 diff를 검토하면서 받아들일 부분만 골라 커밋할 때 특히 유용하다.

## 2. Forge — GitHub Enterprise PR/issue

[설치와 준비물](/setup/)의 토큰 설정이 먼저 되어 있어야 한다. `github.daumkakao.com`이 등록돼 있다.

magit status에서:

| 키 | 동작 |
|---|---|
| `f f` | fetch (forge 데이터 포함 갱신은 `N f f`) |
| `N` | forge 메뉴 (pullreq/issue 목록, 생성 등) |

- status 버퍼 하단에 "Pull requests", "Issues" 섹션이 생긴다. `RET`으로 열어 본문/코멘트를 읽는다.
- PR 생성: 브랜치를 push한 뒤 `N c p` — 제목/본문 작성 후 `C-c C-c`

## 3. 추천 루틴 (커밋까지)

1. `C-x g` — 무엇이 바뀌었는지 훑기
2. `TAB`으로 diff 확인하며 `s`로 stage
3. `c c` — 커밋 메시지 작성, `C-c C-c`
4. `P p` — push
5. `N c p` — PR 생성 (또는 웹에서)

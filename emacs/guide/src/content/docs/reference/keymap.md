---
title: 전체 키맵
description: 이 설정의 커스텀 키 전체 목록
---

prefix별로 정리한 커스텀 키 전체 목록. 바닐라 Emacs 기본 키는 `emacs/reference-card.html` 참고.

## 이동/검색

| 키 | 동작 |
|---|---|
| `C-s` | 현재 버퍼 검색 (consult-line) |
| `C-x b` | 버퍼 전환 (consult-buffer) |
| `M-s r` | 프로젝트 ripgrep 검색 |
| `M-g g` | 줄 번호로 이동 |
| `M-g s` | 워크스페이스 심볼 검색 (IntelliJ `Cmd+O`) |
| `M-.` / `M-,` | 정의로 이동 / 되돌아오기 |
| `M-?` | 사용처 찾기 (Find Usages) |

## LSP — `C-c l`

| 키 | 동작 |
|---|---|
| `C-c l a` | code action (IntelliJ `Opt+Enter`) |
| `C-c l r` | rename (`Shift+F6`) |
| `C-c l f` | format |
| `C-c l d` | 버퍼 진단 목록 |
| `C-c l g d` | 정의로 이동 (= `M-.`) |
| `C-c l g r` | 참조 찾기 (= `M-?`) |
| `C-c l g i` | 구현체로 이동 |
| `C-c l g t` | 타입 정의로 이동 |
| `C-c l g b` | 뒤로 가기 (= `M-,`) |
| `C-c l g s` | 심볼 검색 (= `M-g s`) |

## Gradle — `C-c g`

| 키 | 동작 |
|---|---|
| `C-c g t` | 커서 위치 테스트 메서드 실행 |
| `C-c g c` | 현재 클래스 테스트 실행 |
| `C-c g m` | 현재 모듈 테스트 실행 |
| `C-c g r` | 마지막 명령 재실행 |
| `C-c g b` | bootRun (`C-u`로 profile 지정) |
| `C-c g d` | 테스트 메서드 디버그 (자동 attach) |
| `C-c g D` | 테스트 클래스 디버그 |

## 디버거 — `C-c d`

| 키 | 동작 |
|---|---|
| `C-c d d` | 디버그 세션 시작 (`jvm-attach`, `debugpy-attach`) |
| `C-c d b` | breakpoint 토글 |
| `C-c d B` | 조건부 breakpoint |
| `C-c d D` | breakpoint 전부 제거 |
| `C-c d c` | continue |
| `C-c d n` | step over |
| `C-c d i` | step in |
| `C-c d o` | step out |
| `C-c d q` | 세션 종료 |
| `C-c d r` | 디버그 REPL |
| `C-c d w` | watch 추가 |
| `C-c d l` | 정보 창 (스택/변수/breakpoint) |

## 진단 — flymake

| 키 | 동작 |
|---|---|
| `M-g n` / `M-g p` | 다음/이전 에러로 점프 (compilation 버퍼에서도 동일) |
| `M-g d` | 버퍼 진단 목록 |
| `M-g f` | 진단 검색 (consult-flymake) |

## 프로젝트/트리/Git

| 키 | 동작 |
|---|---|
| `C-c p p` | 프로젝트 전환 |
| `C-c p f` | 프로젝트 파일 찾기 |
| `C-c t t` | treemacs 토글 |
| `C-c t s` | treemacs 창으로 이동 |
| `C-x g` | magit status |

## 편집/기타

| 키 | 동작 |
|---|---|
| `C-S-d`, `M-S-↓` | 줄 아래로 복제 |
| `M-S-↑` | 줄 위로 복제 |
| `C-x C-b` | ibuffer |
| `C-c a` / `C-c c` / `C-c o l` | org agenda / capture / link 저장 |

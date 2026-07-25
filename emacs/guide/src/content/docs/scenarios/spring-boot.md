---
title: Spring Boot 실행
description: bootRun, profile 지정, 로그 확인
---

**상황**: 로컬에서 애플리케이션을 띄워 API를 직접 확인하고 싶다.

## 실행

프로젝트(해당 모듈) 안의 아무 파일에서:

| 키 | 동작 |
|---|---|
| `C-c g b` | `./gradlew [모듈:]bootRun` 실행 |
| `C-u C-c g b` | profile을 물어본 뒤 `--spring.profiles.active=<profile>`로 실행 |

멀티모듈이면 현재 파일이 속한 모듈의 `bootRun`을 실행한다. 예를 들어 `app/api` 모듈의 파일에서 누르면 `./gradlew :app:api:bootRun`.

## 로그 보기

출력은 `*gradle: 프로젝트명*` 버퍼에 실시간으로 흐른다 (ANSI 컬러 렌더링됨).

- 스택트레이스가 찍히면 `M-g n`으로 해당 소스 라인에 점프
- 로그 안 텍스트 검색은 그 버퍼에서 `C-s`
- 중지: compilation 버퍼에서 `C-c C-k` (kill-compilation)

## 디버그 모드로 띄우기

Emacs 밖 터미널에서 `--debug-jvm`으로 띄우고 attach하는 흐름이 더 유연하다.

```bash
./gradlew bootRun --debug-jvm
```

이후 [디버깅하기 — 시나리오 B](/scenarios/debug/#시나리오-b-실행-중인-spring-boot에-attach) 참고.

:::tip
서버를 오래 띄워 두고 코드도 계속 만질 거면, bootRun은 tmux 터미널에서 돌리고 Emacs는 편집/테스트에 쓰는 분업이 편할 때가 많다. Emacs의 `C-c g b`는 "잠깐 띄워서 확인"용으로 적합하다.
:::

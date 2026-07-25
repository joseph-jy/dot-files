---
title: 트러블슈팅
description: 자주 겪는 문제와 해결
---

## LSP

**자동완성/정의 이동이 안 된다**
- 모드라인에 `eglot` 표시가 있는지 확인. 없으면 언어 서버 미설치 — `which jdtls`(Java), `which kotlin-language-server`(Kotlin)로 확인 후 [설치](/setup/).
- 서버는 있는데 시작이 안 됐으면 `M-x eglot`으로 수동 시작.

**Java 프로젝트가 이상하게 인식된다 (의존성 빨간 줄 등)**
- jdtls 인덱싱이 끝나기 전일 수 있다. 잠시 기다린다.
- Gradle 설정을 바꿨다면 `M-x eglot-reconnect`.
- 그래도 안 되면 jdtls 워크스페이스 캐시가 깨진 것일 수 있다. `M-x eglot-shutdown` 후 재시작.

**Kotlin에서 kotlin-lsp 관련 에러**
- JetBrains `kotlin-lsp`는 intellij-server build 만료 이슈가 있어 `kotlin-language-server`를 기본으로 쓴다. 후자가 설치돼 있는지 확인.

## 디버깅

**`jdtls eglot 세션이 없다` 에러**
- 같은 프로젝트의 **Java 파일**을 하나 열어 eglot 세션을 먼저 만들어야 한다. Kotlin 버퍼만 열려 있으면 이 에러가 난다.

**attach는 되는데 breakpoint에서 안 멈춘다**
- `~/.local/share/java-debug/`에 번들 jar가 있는지 확인 — 없으면 [설치](/setup/) 후 `M-x eglot-reconnect`.
- 소스와 실행 중인 바이트코드가 다르면(재빌드 안 함) 안 멈춘다.

**`C-c g d`를 눌렀는데 attach가 안 된다**
- Gradle 출력에 `Listening for transport dt_socket ...`이 떴는지 확인. 이 라인을 감지해 attach하므로, 테스트가 그 전에 컴파일 에러로 죽었으면 attach도 없다.

## Gradle 러너

**"메서드를 감지하지 못했다"** — 커서를 테스트 메서드 **본문 안**에 둔다. `@Nested` 중첩 클래스에서는 감지가 부정확할 수 있으니 `C-c g c`(클래스 단위)로 우회.

**"gradlew를 찾을 수 없다"** — 현재 파일 상위에 `gradlew`가 없다. Gradle 프로젝트 안의 파일에서 실행한다.

## Forge

**PR 목록이 안 보인다**
- `~/.authinfo.gpg`의 machine 라인과 `git config github.github.daumkakao.com.user` 설정 확인 → [설치](/setup/).
- magit status에서 `N f f`로 forge fetch를 한 번 해야 목록이 채워진다.

## 기타

**아이콘이 네모로 깨진다** — `M-x nerd-icons-install-fonts` 실행 후 재시작.

**뭔가 꼬여서 미니버퍼가 이상하다** — `C-g` 연타. 그래도 안 되면 `ESC ESC ESC`.

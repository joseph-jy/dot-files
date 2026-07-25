# Emacs를 IntelliJ 대체 IDE로 만드는 계획

작성일: 2026-07-25. 다음 세션부터 이 문서를 기준으로 작업한다.

## 진행 기록 (2026-07-25 구현)

Phase 0–4, 6 구현 완료. 남은 것은 **업무 Gradle 멀티모듈 프로젝트에서의 실측
검증**과 Phase 5(kotlin-lsp 재평가)다.

로컬에서 검증된 것:

- jdtls가 java-debug 0.53.1 번들을 싣고 기동, `vscode.java.startDebugSession`
  / `resolveClasspath` 명령 등록 확인 (실제 eglot 세션으로 확인)
- 모듈 감지(`:app:core`), FQN/메서드 감지 (Java: which-function,
  Kotlin: 정규식 폴백 — kotlin-mode가 imenu를 제공하지 않음. 백틱 이름 지원)
- kotlinc 에러(신/구 포맷)와 JUnit 스택트레이스의 compilation 파싱,
  FQN → `git ls-files` 소스 경로 해석
- `jvm-attach`/`debugpy-attach` dape 설정 등록과 `:port` 오버라이드

업무 프로젝트에서 확인할 것 (최종 검증 시나리오 1–8):

- dape + jdtls 번들 조합의 breakpoint/step 동작 (특히 **Kotlin 파일의
  breakpoint를 java-debug가 잡는지** — 안 되면 리스크 표의 대비책대로)
- `--debug-jvm` 포트 자동 감지 → attach 플로우 (`C-c g d`)
- `@Nested`/중첩 클래스 테스트에서 메서드 감지 정확도 (부정확하면
  `jy/gradle-method-at-point-function`을 treesit 구현으로 교체)

참고: lsp-java/dap-mode 제거는 "동작 확인 후" 원칙이었으나 단일 커밋으로
분리해 두었으므로 문제가 생기면 해당 커밋만 revert하면 된다.

## 배경과 목표

에이전트 코딩 도구를 쓰면서 IntelliJ의 사용 비중이 계속 줄고 있다. 코드 작성/수정은
에이전트가 하므로, Emacs에는 아래 5가지만 IntelliJ 수준으로 남기면 된다.

1. 디버거 (breakpoint, step, 변수 확인, JVM attach)
2. Find Usages
3. 코드 탐색 (GoTo definition / implementation / class / symbol)
4. 빌드 / 실행 (테스트 메서드별, 클래스별 실행과 디버그)
5. 파일 탐색

**비목표** (IntelliJ full feature는 재현하지 않는다):

- Code Completion 고도화 — corfu 기본 동작이면 충분, 더 투자하지 않음
- 리팩터링 도구 (rename 정도만 유지)
- 코드 생성, 인스펙션, 서드파티 플러그인 생태계

대상 언어/빌드: Java, Kotlin, Gradle, Spring Boot.

## 현재 상태 진단

`init.el` 기준으로 이미 되는 것과 안 되는 것.

| 기능 | 현재 상태 | 진단 |
|---|---|---|
| GoTo definition/implementation | eglot + xref (`M-.`, `C-c l g i`) | 동작함 |
| GoTo class/symbol (프로젝트 전역) | **없음** | IntelliJ `Cmd+O`/`Cmd+Opt+O` 대응 부재. consult-eglot 필요 |
| Find Usages | `xref-find-references` (`M-?`) | 동작하나 결과 UX가 IntelliJ 대비 빈약 |
| 파일 탐색 | projectile + consult + treemacs | 충분함. 손대지 않음 |
| 테스트 메서드/클래스별 실행 | **없음** (수동으로 gradle 명령 입력) | 핵심 결손. Gradle 러너 elisp 필요 |
| 디버거 (attach) | dap-mode + `JVM Attach localhost:5005` | 동작하나 아래 문제 있음 |
| 디버거 (test debug) | lsp-java 필요 → `eglot-shutdown` 후 `M-x lsp` 수동 전환 | **최대 고통 지점.** LSP 이중 스택 |
| Kotlin test debug | dap-java는 Java 전용이라 **불가** | gradle `--debug-jvm` + attach만 가능 |

결론: LSP 이중 스택(eglot ↔ lsp-java 전환 댄스)을 없애고, 테스트 러너를 만드는 것이
이번 작업의 핵심이다.

## 아키텍처 결정

**eglot 단일 스택 + dape + Gradle CLI 러너.** lsp-java와 dap-mode는 제거한다.

```
편집/탐색:  eglot (jdtls, kotlin-lsp) ─ 지금과 동일
디버거:     dape  ─ eglot의 jdtls 세션을 그대로 사용 (java-debug 번들 주입)
테스트 실행: 직접 작성한 elisp → ./gradlew :module:test --tests 'FQN.method'
테스트 디버그: 같은 명령 + --debug-jvm → dape가 5005 포트로 auto-attach
```

근거:

- [dape](https://github.com/svaante/dape)는 eglot이 띄운 jdtls에 java-debug 플러그인
  번들을 실어 디버그 세션을 시작한다. 공식 문서 인용: *"The Java config depends on
  Eglot running JDTLS with the plugin prior to starting Dape."*
  → `eglot-shutdown` → `M-x lsp` 전환 댄스가 완전히 사라진다.
- 테스트 실행/디버그를 **Gradle CLI 기반으로 통일**하면 Java와 Kotlin이 같은 플로우를
  쓴다 (dap-java의 test-method 디버그는 Java 전용이었음). IntelliJ도 내부적으로
  Gradle test runner에 위임하는 방식과 동일한 모델이다.
- lsp-java + dap-mode 스택(및 관련 패키지 treemacs 연동 등)을 걷어내면 설정
  복잡도가 크게 줄고, README의 "디버깅 전 eglot 끄기" 안내도 삭제된다.

대안 검토 후 기각:

- **lsp-mode로 전면 전환**: dap-java의 test debug가 IntelliJ와 가장 비슷하지만
  Kotlin 미지원, 스택 전체 교체 비용, 현재 eglot 중심 방향과 충돌. 기각.
- **kotlin용 별도 DAP 어댑터(kotlin-debug-adapter)**: 유지보수 침체, JVM attach로
  충분하므로 불필요. 기각.

## 단계별 작업 계획

각 Phase는 독립적으로 커밋 가능하며, 완료 조건을 만족해야 다음으로 넘어간다.
**Phase 순서는 위험도 순**이다: 탐색(안전) → 러너(신규 코드) → 디버거(스택 교체).

### Phase 0 — 사전 준비와 검증

- [x] [microsoft/java-debug](https://github.com/microsoft/java-debug)의
  `com.microsoft.java.debug.plugin-<ver>.jar` 다운로드. 위치는
  `~/.local/share/java-debug/` 같은 고정 경로로 두고 init.el에서 참조.
  (brew jdtls와 별개 아티팩트임. Maven Central에서 받거나 VS Code Java Debug
  확장 vsix에서 추출)
- [x] eglot의 jdtls 서버 엔트리에 `:initializationOptions (:bundles [...])`로 번들
  주입이 되는지 확인. 현재 init.el의 jdtls 엔트리는 실행 파일 이름만 있으므로
  contact 함수 형태로 수정 필요.
- [x] dape 설치 후 `dape-configs`에 `jdtls` 엔트리가 인식되는지 확인.

완료 조건: Java 파일에서 eglot이 번들 포함으로 기동되고, jdtls 로그에 java-debug
플러그인 로드가 보인다.

### Phase 1 — 코드 탐색 / Find Usages 보강 (저위험)

- [x] `consult-eglot` 추가 → `consult-eglot-symbols`로 워크스페이스 심볼 검색.
  IntelliJ `Cmd+O`(클래스), `Cmd+Opt+O`(심볼) 대응. 키는 `C-c l g s` 및 짧은 전역 키
  하나 (예: `M-g s`).
- [x] xref 결과를 consult로: `xref-show-xrefs-function`을 `consult-xref`로 설정
  → Find Usages 결과가 미리보기 되는 minibuffer 목록으로 나옴.
- [x] (선택) call hierarchy: `eglot-hierarchy` 등 외부 패키지 상태를 확인해보고
  쓸만하면 추가, 아니면 references로 충분하다고 결론 내리고 종료.
  → consult-xref 미리보기 references로 충분하다고 보고 일단 종료.
  실사용에서 아쉬우면 재검토.

완료 조건: 업무 Gradle 멀티모듈 프로젝트에서 클래스명 일부로 파일을 열고, 메서드
참조를 미리보기로 훑을 수 있다.

### Phase 2 — Gradle 빌드/테스트 러너 (핵심 신규 코드)

`jy/gradle.el` (또는 init.el 내 섹션)로 작성. 모두 `compile` 기반이라
`M-g n`으로 에러 위치 점프가 된다.

- [x] **모듈 감지**: 현재 파일에서 가장 가까운 `build.gradle(.kts)`를 찾아
  루트로부터의 Gradle path(`:app:core` 형태)를 계산.
- [x] **테스트 대상 감지**: 현재 버퍼에서 FQN과 메서드명을 얻는다.
  - 패키지: 버퍼 상단 `^package` 정규식
  - 클래스: 파일명 기반 + 중첩 클래스는 imenu/treesit로 보정
  - 메서드: point 기준 enclosing function — 1차 구현은 imenu/`which-function`,
    부족하면 treesit(java-ts-mode / kotlin-ts-mode) 기반으로 교체
- [x] 명령 4종:
  - `jy/gradle-test-at-point` → `./gradlew :mod:test --tests 'FQN.method'`
  - `jy/gradle-test-class` → `./gradlew :mod:test --tests 'FQN'`
  - `jy/gradle-test-module` → `./gradlew :mod:test`
  - `jy/gradle-rerun` → 마지막 명령 재실행 (IntelliJ `Ctrl+R` 대응, 가장 자주 씀)
- [x] Spring Boot: `jy/gradle-boot-run` (+ profile 물어보는 변형).
- [x] compile 버퍼 품질: `ansi-color-compilation-filter` 훅, Gradle/Kotlin 컴파일러
  에러 및 JUnit 실패 스택트레이스용 `compilation-error-regexp-alist` 엔트리 추가
  → 실패 테스트에서 소스로 점프 가능하게.
- [x] 키 prefix 신설: `C-c g` (gradle) — `t`(at point) / `c`(class) / `m`(module) /
  `r`(rerun) / `b`(bootRun).

완료 조건: 업무 프로젝트의 아무 테스트 파일에서 커서만 놓고 `C-c g t` →
해당 메서드만 실행되고, 실패 시 스택트레이스에서 소스로 점프된다. Java/Kotlin 모두.

### Phase 3 — 디버거를 dape로 전환

- [x] `dape` 설치, `dape-configs` 구성:
  - `jdtls` (launch — dape 내장 설정 활용)
  - `jvm-attach` (`:request "attach" :hostName "localhost" :port 5005`)
- [x] dape UI 익히기/조정: breakpoint fringe 표시, `dape-info`(locals, stack,
  breakpoints), `dape-repl`.
- [x] 키바인딩: 기존 `C-c d` prefix를 dape로 재배치
  (`d`ebug, `b`reakpoint, `c`ontinue, `n`ext, `i`n, `o`ut, `q`uit, `r`epl, `w`atch).
- [x] K8s 원격 디버그 플로우 유지 확인: `kubectl port-forward` + `jvm-attach`.
- [x] 전부 동작 확인 후 **lsp-java, dap-mode 제거** 및 README의
  "eglot-shutdown 후 M-x lsp" 섹션 삭제.

완료 조건: breakpoint 찍고 `bootRun --debug-jvm`에 attach → 변수 확인, step이
된다. 이 과정에서 `M-x lsp`를 한 번도 치지 않는다.

### Phase 4 — 테스트 디버그 원버튼 플로우 (IntelliJ의 "Debug Test" 대응)

- [x] `jy/gradle-debug-test-at-point`: Phase 2의 명령에 `--debug-jvm`을 붙여
  compile 실행 → compilation filter에서
  `Listening for transport dt_socket at address: 5005` 감지 → 자동으로
  `jvm-attach` dape 세션 시작.
- [x] 클래스 단위 변형 `jy/gradle-debug-test-class`.
- [x] 키: `C-c g d` (method), `C-c g D` (class).

완료 조건: Kotlin 테스트 메서드에 breakpoint를 찍고 `C-c g d` 한 번으로 breakpoint에
멈춘다. (Kotlin에서 되면 Java는 자동으로 된다)

### Phase 5 — Kotlin LSP 안정화 확인

- [ ] JetBrains `kotlin-lsp` 최신 빌드에서 intellij-server build 만료 이슈가
  해소됐는지 재평가. 업무 프로젝트에서 find usages / goto 품질을
  `kotlin-language-server`와 비교.
- [ ] 결과에 따라 `jy/kotlin-eglot-server` 우선순위 조정.

완료 조건: Kotlin 파일에서 5가지 핵심 기능이 Java와 동등하게 동작하거나, 격차를
이 문서 하단에 기록한다.

### Phase 6 — 문서/치트시트 정리

- [x] `emacs/README.md`: 이중 LSP 스택 안내 삭제, Gradle 러너/dape 플로우로 재작성.
- [x] `emacs/cheatsheet.html`: `C-c g`, `C-c d`(dape), `M-g s` 등 키 변경 반영.
  (AGENTS.md 규칙: 키바인딩 변경과 같은 커밋에서 갱신)
- [x] "먼저 익힐 키" 목록 갱신.

## 최종 검증 시나리오 (실제 업무 프로젝트에서)

IntelliJ를 켜지 않고 아래를 전부 수행할 수 있으면 완료:

1. 클래스 이름 일부로 파일 열기 (`consult-eglot-symbols`)
2. 서비스 메서드에서 `M-?` → 호출처 목록 미리보기로 훑기
3. 인터페이스에서 구현체로 점프 (`C-c l g i`)
4. 테스트 메서드 하나만 실행 → 실패 스택트레이스에서 소스 점프
5. 같은 테스트를 원버튼 디버그 → breakpoint에서 변수 확인, step over/in
6. `bootRun --debug-jvm`으로 로컬 서버 띄우고 attach 디버그
7. K8s pod에 port-forward 후 attach 디버그
8. 위 1–7을 Kotlin 코드에서도 반복

## 리스크와 대비책

| 리스크 | 대비 |
|---|---|
| dape + jdtls 번들 조합이 회사 멀티모듈에서 불안정 | Phase 3에서 lsp-java/dap-mode 제거는 **동작 확인 후에만** 수행. 실패 시 attach 전용으로라도 dape를 쓰고 launch는 gradle CLI로 우회 |
| `--debug-jvm`은 Gradle daemon/test JVM fork 설정에 따라 포트가 다를 수 있음 | compilation output에서 포트를 파싱해 attach (하드코딩 금지) |
| kotlin LSP 품질 (find usages 누락 등) | Phase 5에서 실측 후 서버 선택. 최악의 경우 Kotlin 탐색만 `consult-ripgrep` 보조 |
| imenu 기반 메서드 감지가 중첩 클래스/`@Nested` 테스트에서 부정확 | treesit 기반 감지로 교체할 것을 전제로 감지 함수를 인터페이스로 분리해 둠 |
| jdtls 메모리 부족 (대형 모노레포) | `JAVA_OPTS`/jdtls `-Xmx` 조정 항목을 Phase 0 체크리스트에 포함 |

## 이 계획에서 의도적으로 안 하는 것

- corfu/completion 개선, snippet, AI completion — 에이전트가 코드를 쓰므로 불필요
- lsp-mode 전환 — eglot 단일 스택 유지가 원칙
- Emacs 배포판(Doom/Spacemacs) 도입 — 기존 vanilla 설정 위에 증분으로만 작업

# Emacs Setup

Vanilla Emacs를 Java/Kotlin 백엔드 개발, AI agent 결과 리뷰, GitHub Enterprise PR 확인에 맞게 가볍게 운영한다.

## 현재 방향

- `eglot`: Java/Kotlin/TypeScript/Python/Bash/YAML LSP 클라이언트 (단일 LSP 스택)
- `magit` + `forge`: Git 및 GitHub Enterprise PR/issue 확인
- `projectile` + `consult` + `consult-eglot`: 프로젝트 이동, 파일/텍스트/심볼 검색
- `treemacs`: 좌측 디렉토리/프로젝트 사이드바
- `corfu`: 버퍼 안 completion
- `flymake`: Eglot 진단 확인
- `dape`: 디버거 — eglot의 jdtls 세션을 그대로 사용 (JVM/Python attach, test debug)
- `lisp/jy-gradle.el`: Gradle 테스트 러너 (`C-c g`) — 메서드/클래스 단위 실행·디버그
- `org`: 할 일, 회의/리뷰 메모

IntelliJ 대체 계획과 진행 상황은 `IDE-PLAN.md` 참고.

## 필수 도구

현재 설정은 언어 서버 실행 파일이 있을 때만 Eglot을 시작한다. 없는 서버 때문에 파일을 열 때 에러가 나지 않는다.

```bash
# Java
brew install jdtls

# Kotlin: 현재 설정은 kotlin-language-server 우선, 없으면 공식 JetBrains LSP 사용
brew install JetBrains/utils/kotlin-lsp
brew install kotlin-language-server

# TypeScript / TSX
npm install -g typescript-language-server typescript

# YAML / Kubernetes
brew install yaml-language-server

# Python
brew install pyright

# Bash
brew install bash-language-server shellcheck
```

디버깅에는 microsoft/java-debug 플러그인 jar가 필요하다. eglot이 jdtls를 띄울 때
`~/.local/share/java-debug/`의 jar를 자동으로 주입한다.

```bash
mkdir -p ~/.local/share/java-debug
curl -fL -o ~/.local/share/java-debug/com.microsoft.java.debug.plugin-0.53.1.jar \
  https://repo1.maven.org/maven2/com/microsoft/java/com.microsoft.java.debug.plugin/0.53.1/com.microsoft.java.debug.plugin-0.53.1.jar
```

JetBrains `kotlin-lsp`는 intellij-server build 만료 이슈가 생길 수 있어 `kotlin-language-server`를 기본값으로 둔다. `kotlin-lsp`를 최신 build로 갱신해 안정화되면 `jy/kotlin-eglot-server`의 우선순위를 다시 바꾼다.

## 빌드/테스트 (Gradle 러너)

`lisp/jy-gradle.el`이 IntelliJ의 test runner를 대체한다. 테스트 파일에 커서만 놓고:

- `C-c g t`: 커서 위치의 테스트 메서드 하나만 실행
- `C-c g c`: 현재 클래스 테스트 전부 실행
- `C-c g m`: 현재 모듈 테스트 전부 실행
- `C-c g r`: 마지막 명령 재실행 (IntelliJ `Ctrl+R` 대응)
- `C-c g b`: Spring Boot `bootRun` (`C-u`로 profile 지정)

모듈(`:app:core`), 클래스 FQN, 메서드 이름을 자동으로 감지해
`./gradlew :app:core:test --tests 'FQN.method'`를 `compile`로 실행한다.
Java/Kotlin 모두 지원하고 Kotlin 백틱 테스트 이름도 잡는다.
실패하면 스택트레이스에서 `M-g n`으로 소스에 점프한다.

## 디버깅

디버거는 `dape`를 사용한다. dape는 eglot이 띄운 jdtls의 java-debug 번들로
디버그 세션을 시작하므로 **LSP 전환 없이** 평소 세션 그대로 디버깅한다.
(예전의 `eglot-shutdown` 후 `M-x lsp` 전환은 더 이상 필요 없다.)

### 테스트 디버그 (원버튼)

breakpoint를 찍고(`C-c d b`):

- `C-c g d`: 커서 위치의 테스트 메서드를 `--debug-jvm`으로 실행
- `C-c g D`: 클래스 단위

Gradle 출력에서 `Listening for transport dt_socket ...` 포트를 감지해
자동으로 dape attach 세션이 시작된다. Java/Kotlin 동일한 플로우다.

### JVM attach

이미 debug mode로 떠 있는 JVM에는 직접 attach한다.

```bash
# Spring Boot / application
./gradlew bootRun --debug-jvm

# 직접 JVM 옵션을 넣을 때
-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005
```

Emacs에서 `C-c d d` 후 `jvm-attach`를 선택한다 (기본 localhost:5005,
`jvm-attach :port 5006`처럼 미니버퍼에서 덮어쓸 수 있다).
attach 전에 같은 프로젝트의 Java 파일이 한 번은 열려 있어야 한다
(jdtls 세션이 debug adapter를 제공하므로).

### K8s 원격 JVM

K8s에서는 debug port를 외부로 직접 열지 말고 port-forward로 연결한다.

```bash
kubectl port-forward pod/<pod-name> 5005:5005
```

그 다음 Emacs에서 `jvm-attach`를 선택한다.

### Python

이미 실행 중인 프로세스에 attach하려면 target process를 다음처럼 띄운다.

```bash
python -m pip install debugpy
python -m debugpy --listen 5678 --wait-for-client script.py
```

Emacs에서는 `C-c d d` 후 `debugpy-attach`를 선택한다.

## GitHub Enterprise / Forge

`init.el`에는 `github.daumkakao.com`이 등록되어 있다. Forge를 쓰려면 토큰과 username 설정이 필요하다.

```bash
git config --global github.github.daumkakao.com.user <github-username>
```

`~/.authinfo.gpg`에는 다음 형식으로 저장한다.

```text
machine github.daumkakao.com/api/v3 login <github-username>^forge password <token>
```

토큰 scope는 일반적으로 `repo`, `user`, `read:org`가 필요하다.

## 단축키 유지보수 규칙

`emacs/init.el`에서 package, keybinding, prefix map, debug template, LSP command, Git/Magit/Treemacs 흐름을 바꾸면 같은 변경 안에서 `emacs/cheatsheet.html`도 함께 확인하고 갱신한다. `emacs/README.md`의 "먼저 익힐 키" 목록을 바꿀 때도 동일하게 `emacs/cheatsheet.html`을 맞춘다.

`emacs/reference-card.html`은 일반 Emacs 기본 키 레퍼런스이므로 개인 설정 변경만으로는 수정하지 않는다.

## 먼저 익힐 키

- `C-x C-f`: 파일 열기
- `C-x b`: 버퍼 전환
- `C-x 1`, `C-x 2`, `C-x 3`, `C-x 0`: 창 제어
- `C-s`: 현재 버퍼 검색
- `M-s r`: 프로젝트 ripgrep 검색
- `C-c t`: Treemacs 디렉토리/프로젝트 사이드바 열기
- `C-c p f`: 프로젝트 파일 찾기
- `C-x g`: Magit status
- `C-c o l`: Org link 저장
- `M-.`: 정의로 이동
- `M-,`: 이전 위치로 복귀
- `M-g s`: 워크스페이스 클래스/심볼 검색 (IntelliJ `Cmd+O` 대응)
- `M-?`: 참조 위치 모두 찾기 (Find Usages)
- `C-c l a`: LSP code action
- `C-c l r`: LSP rename
- `C-c l f`: LSP format
- `C-c l d`: 현재 버퍼 진단 목록
- `C-c l g i`: 인터페이스 구현체로 이동
- `C-c g t`: 커서 위치 테스트 메서드 실행
- `C-c g r`: 마지막 Gradle 명령 재실행
- `C-c g d`: 테스트 메서드 디버그 (자동 attach)
- `C-c d d`: 디버그 세션 시작 (jvm-attach 등)
- `C-c d b`: breakpoint toggle
- `C-c d c`: continue
- `C-c d n`: step over
- `C-c d i`: step in
- `C-c d o`: step out
- `C-c d q`: 디버그 세션 종료

## 학습 로드맵

### 1주차: 생존 키와 검색

파일/버퍼/창 전환, `consult-line`, `consult-ripgrep`, `projectile-find-file`만 반복한다. 이 단계에서는 IDE 기능을 욕심내지 말고 AI agent가 만든 diff를 빠르게 찾고 읽는 데 집중한다.

### 2주차: 코드 읽기

Java/Kotlin 프로젝트에서 `M-.`, `M-,`, references, hover, code action을 익힌다. 목표는 직접 많이 작성하는 것이 아니라 agent 결과가 어느 call path에 영향을 주는지 빠르게 확인하는 것이다.

### 3주차: Git과 PR

`C-x g`로 status, diff, hunk stage, commit amend를 익힌다. Forge 토큰 설정 후 PR/issue를 Emacs에서 보는 흐름을 붙인다.

### 4주차: JVM/K8s 실무

`jdtls`, `kotlin-lsp`, `yaml-language-server`가 실제 회사 프로젝트에서 잘 붙는지 확인한다. K8s manifest는 Emacs에서 수정하되, cluster 조작은 기존처럼 `kubectl`, `helm`, `k9s`, tmux를 병행한다.

### 이후: AI agent 운영 허브

Emacs는 코드 리뷰와 작은 수정을 위한 메인 화면으로 두고, 긴 작업은 Codex/Claude/tmux 세션에서 돌린다. 결과 확인은 `magit`, `consult-ripgrep`, `eglot`, `org-capture`로 처리한다.

# Emacs Setup

Vanilla Emacs를 Java/Kotlin 백엔드 개발, AI agent 결과 리뷰, GitHub Enterprise PR 확인에 맞게 가볍게 운영한다.

## 현재 방향

- `eglot`: Java/Kotlin/TypeScript/Python/Bash/YAML LSP 클라이언트
- `magit` + `forge`: Git 및 GitHub Enterprise PR/issue 확인
- `projectile` + `consult`: 프로젝트 이동, 파일/텍스트 검색
- `treemacs`: 좌측 디렉토리/프로젝트 사이드바
- `corfu`: 버퍼 안 completion
- `flymake`: Eglot 진단 확인
- `dap-mode`: JVM/Python debug attach 및 Java test debug
- `org`: 할 일, 회의/리뷰 메모

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

JetBrains `kotlin-lsp`는 intellij-server build 만료 이슈가 생길 수 있어 `kotlin-language-server`를 기본값으로 둔다. `kotlin-lsp`를 최신 build로 갱신해 안정화되면 `jy/kotlin-eglot-server`의 우선순위를 다시 바꾼다.

## 디버깅

Emacs 디버깅은 `dap-mode`를 사용한다. 일상 코드 탐색은 Eglot으로 유지하고, Java launch/test debug처럼 `lsp-java`가 필요한 기능만 디버깅 세션에서 별도로 켠다.

### JVM attach 우선

Spring Boot, Gradle test, K8s process는 JVM을 debug mode로 띄운 뒤 Emacs에서 attach한다.

```bash
# Spring Boot / application
./gradlew bootRun --debug-jvm

# 특정 테스트
./gradlew test --debug-jvm --tests 'com.example.SomeTest'

# 직접 JVM 옵션을 넣을 때
-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005
```

Emacs에서는 `C-c d d` 후 `JVM Attach localhost:5005`를 선택한다.

주의: Java DAP adapter는 `lsp-java`의 JDT LS workspace를 사용한다. JVM attach가 adapter 문제로 실패하면 Java/Kotlin 버퍼에서 먼저 `M-x eglot-shutdown` 후 `M-x lsp`를 실행하고 다시 attach한다. 평소 편집은 계속 Eglot을 사용하면 된다.

### Java main/test debug

IntelliJ에 가까운 Java main/test debug는 `lsp-java`가 필요하다.

1. Java 파일을 연다.
2. `M-x eglot-shutdown`으로 현재 버퍼의 Eglot 세션을 끈다.
3. `M-x lsp`로 `lsp-java` workspace를 시작한다.
4. `C-c d d`로 `Java Run Configuration`, `Java Attach` 등을 선택한다.
5. 테스트 메서드/클래스는 `M-x dap-java-debug-test-method`, `M-x dap-java-debug-test-class`를 사용한다.

이 흐름은 JDT LS가 classpath, test runner, debug server를 계산해야 하므로 Eglot만으로는 충분하지 않다.

### K8s 원격 JVM

K8s에서는 debug port를 외부로 직접 열지 말고 port-forward로 연결한다.

```bash
kubectl port-forward pod/<pod-name> 5005:5005
```

그 다음 Emacs에서 `JVM Attach localhost:5005`를 선택한다.

### Python

로컬 launch debug는 프로젝트 virtualenv에 `debugpy`가 필요하다.

```bash
python -m pip install debugpy
```

이미 실행 중인 프로세스에 attach하려면 target process를 다음처럼 띄운다.

```bash
python -m debugpy --listen 5678 --wait-for-client script.py
```

Emacs에서는 `C-c d d` 후 `Python Attach localhost:5678`을 선택한다.

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
- `C-c l a`: LSP code action
- `C-c l r`: LSP rename
- `C-c l f`: LSP format
- `C-c l d`: 현재 버퍼 진단 목록
- `C-c l g r`: 참조 위치 모두 찾기
- `C-c d d`: debug configuration 실행
- `C-c d b`: breakpoint toggle
- `C-c d c`: continue
- `C-c d n`: step over
- `C-c d i`: step in
- `C-c d o`: step out
- `C-c d q`: debug disconnect

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

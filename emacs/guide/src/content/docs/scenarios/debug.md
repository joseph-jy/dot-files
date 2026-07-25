---
title: 디버깅하기
description: dape로 테스트 디버그, 로컬/K8s JVM attach
---

디버거는 **dape**를 쓴다. eglot이 띄운 jdtls의 java-debug 번들로 디버그 세션을 열기 때문에, LSP를 전환하거나 별도 서버를 띄울 필요 없이 평소 세션 그대로 디버깅한다.

:::note[전제 조건]
- `~/.local/share/java-debug/`에 디버그 번들 jar가 있어야 한다 → [설치와 준비물](/setup/)
- 같은 프로젝트의 **Java 파일이 한 번은 열려 있어야** 한다 (jdtls 세션이 어댑터를 제공하므로). Kotlin만 열려 있으면 attach가 실패한다.
:::

## 시나리오 A: 실패하는 테스트 디버깅 (원버튼)

1. 의심 가는 라인에서 `C-c d b` — breakpoint 토글 (fringe에 표시됨)
2. 테스트 메서드 안에 커서를 두고 `C-c g d` — `--debug-jvm`으로 테스트 실행
3. Gradle 출력에서 JDWP 포트가 감지되면 **자동으로 attach**되고, breakpoint에서 멈춘다
4. 아래 스테핑 키로 진행

클래스 단위로 디버그하려면 `C-c g D`.

## 스테핑 키

| 키 | 동작 | IntelliJ |
|---|---|---|
| `C-c d n` | step over | `F8` |
| `C-c d i` | step in | `F7` |
| `C-c d o` | step out | `Shift+F8` |
| `C-c d c` | continue | `F9` |
| `C-c d q` | 세션 종료 | |

멈춘 상태에서 보는 것:

| 키 | 동작 |
|---|---|
| `C-c d l` | 정보 창 (스택, 변수, breakpoint 목록) — 우측에 뜸 |
| `C-c d w` | 커서의 식을 watch에 추가 |
| `C-c d r` | REPL — 멈춘 컨텍스트에서 식 평가 (IntelliJ Evaluate Expression) |
| `C-c d B` | 조건부 breakpoint (식 입력) |
| `C-c d D` | breakpoint 전부 제거 |

## 시나리오 B: 실행 중인 Spring Boot에 attach

애플리케이션을 디버그 모드로 띄운다.

```bash
./gradlew bootRun --debug-jvm   # 기본 5005 포트에서 대기
```

Emacs에서:

1. breakpoint를 찍는다 (`C-c d b`)
2. `C-c d d` → 목록에서 `jvm-attach` 선택 (기본 localhost:5005)
3. API를 호출해 breakpoint를 밟게 한다

다른 포트면 미니버퍼에서 `jvm-attach :port 5006`처럼 덮어쓴다.

## 시나리오 C: K8s 위의 JVM에 attach

디버그 포트를 외부에 열지 말고 port-forward로 연결한다.

```bash
kubectl port-forward pod/<pod-name> 5005:5005
```

그다음은 시나리오 B와 동일: `C-c d d` → `jvm-attach`.

:::caution
운영 환경 JVM에 breakpoint를 걸면 해당 스레드가 멈춘다. attach 디버깅은 개발/스테이징에서만.
:::

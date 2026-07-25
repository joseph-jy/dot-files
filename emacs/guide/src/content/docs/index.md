---
title: 이 가이드에 대해
description: Java/Kotlin + Spring Boot 개발자를 위한 Emacs 실무 가이드
---

이 가이드는 IntelliJ를 쓰던 Java/Kotlin + Spring Boot 개발자가 이 저장소의 Emacs 설정(`emacs/init.el`)으로 실무를 처리하는 방법을 **시나리오 순서대로** 안내한다. 키를 외우는 문서가 아니라, "이 작업을 할 때 이 순서로 누른다"를 따라 하는 문서다.

## 현재 설정 스택

| 역할 | 도구 | 진입 키 |
|---|---|---|
| LSP (Java/Kotlin 등) | eglot + jdtls / kotlin-language-server | `C-c l` |
| 테스트/빌드 러너 | jy-gradle.el (자작 Gradle 러너) | `C-c g` |
| 디버거 | dape (jdtls의 java-debug 사용) | `C-c d` |
| Git / GitHub Enterprise PR | magit + forge | `C-x g` |
| 프로젝트/파일 이동 | projectile + consult | `C-c p`, `M-s r` |
| 파일 트리 | treemacs | `C-c t t` |
| 자동완성 | corfu | 자동 팝업 |
| 진단(경고/에러) | flymake | `M-g n` / `M-g p` |

## 읽는 순서

1. [설치와 준비물](/setup/) — 언어 서버와 디버그 번들이 깔려 있는지 확인
2. [키 표기법과 기본기](/basics/) — `C-`, `M-` 표기와 창/버퍼 조작
3. 시나리오 문서를 실제 회사 프로젝트를 열어 놓고 하나씩 따라 하기
4. 막히면 [트러블슈팅](/reference/troubleshooting/), 키가 기억 안 나면 [전체 키맵](/reference/keymap/)

:::tip[키를 까먹었을 때]
prefix 키(`C-c l`, `C-c g`, `C-c d`, `C-c p`)를 누르고 잠시 기다리면 **which-key**가 이어서 누를 수 있는 키 목록을 화면 아래에 띄워 준다. 외우지 못한 키는 이걸로 찾으면 된다.
:::

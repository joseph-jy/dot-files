---
title: 설치와 준비물
description: 언어 서버, 디버그 번들, Forge 토큰 설정
---

이 설정은 언어 서버 실행 파일이 **있을 때만** eglot을 시작한다. 서버가 없어도 파일을 여는 데 에러는 나지 않지만, 자동완성·정의 이동·진단이 동작하지 않는다.

## 언어 서버 설치

```bash
# Java
brew install jdtls

# Kotlin (kotlin-language-server 우선, 없으면 JetBrains kotlin-lsp)
brew install kotlin-language-server
brew install JetBrains/utils/kotlin-lsp

# YAML / Kubernetes manifest
brew install yaml-language-server
```

설치 확인: 터미널에서 `which jdtls kotlin-language-server`가 경로를 출력하면 된다.

## 디버그 번들 (Java/Kotlin 디버깅에 필수)

dape 디버거는 jdtls에 실린 microsoft/java-debug 플러그인으로 디버그 세션을 연다. jar 하나만 받아 두면 eglot이 jdtls를 띄울 때 자동 주입한다.

```bash
mkdir -p ~/.local/share/java-debug
curl -fL -o ~/.local/share/java-debug/com.microsoft.java.debug.plugin-0.53.1.jar \
  https://repo1.maven.org/maven2/com/microsoft/java/com.microsoft.java.debug.plugin/0.53.1/com.microsoft.java.debug.plugin-0.53.1.jar
```

## Forge (GitHub Enterprise PR)

Emacs 안에서 PR/issue를 보려면 토큰 설정이 필요하다.

```bash
git config --global github.github.daumkakao.com.user <github-username>
```

`~/.authinfo.gpg`에 한 줄 추가:

```text
machine github.daumkakao.com/api/v3 login <github-username>^forge password <token>
```

토큰 scope는 `repo`, `user`, `read:org`.

## 처음 한 번만

- GUI에서 아이콘이 깨져 보이면 `M-x nerd-icons-install-fonts` 실행
- Java 프로젝트를 처음 열면 jdtls가 인덱싱하느라 수십 초 걸릴 수 있다. 모드라인의 eglot 표시가 안정될 때까지 기다린다.

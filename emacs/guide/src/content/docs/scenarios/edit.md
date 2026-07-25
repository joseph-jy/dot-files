---
title: 코드 수정하기
description: 자동완성, rename, code action, 포맷
---

**상황**: 컨트롤러에 엔드포인트를 하나 추가하고, 서비스 메서드 이름을 바꾸려 한다.

## 1. 자동완성 (corfu)

타이핑을 시작하면 0.2초 뒤 자동으로 후보가 뜬다.

| 키 | 동작 |
|---|---|
| `TAB` 또는 `RET` | 선택한 후보 확정 |
| `C-n` / `C-p` 또는 `↓`/`↑` | 후보 이동 |
| `C-g` | 팝업 닫기 |

import는 jdtls가 completion 확정 시 자동으로 넣어 주는 경우가 많고, 안 들어갔으면 아래 code action으로 처리한다.

## 2. Code Action — IntelliJ `Opt+Enter` 대응

에러/경고 밑줄 위에 커서를 두고:

```
C-c l a
```

"Import 'OrderDto'", "Add @Override" 같은 후보 목록이 뜬다. 고르면 적용된다. **빨간 줄을 만나면 반사적으로 `C-c l a`** 를 누르는 습관을 들이면 IntelliJ의 `Opt+Enter`와 거의 같은 감각으로 쓸 수 있다.

## 3. Rename — 프로젝트 전체 반영

바꾸려는 심볼 위에 커서를 두고:

```
C-c l r
```

새 이름을 입력하면 프로젝트 전체(사용처 포함)가 한 번에 바뀐다. IntelliJ의 `Shift+F6`.

:::caution
rename은 LSP가 인덱스한 범위만 바꾼다. 문자열 안 참조(리플렉션, yml 설정의 클래스명 등)는 못 잡으므로, rename 후 `M-s r`로 옛 이름을 한 번 검색해서 잔재를 확인하는 게 안전하다.
:::

## 4. 포맷

- `C-c l f`: 버퍼(또는 선택 영역) 포맷 — jdtls/kotlin-lsp의 포매터 사용

## 5. 수정 후 확인 루틴

1. `C-x C-s` 저장
2. `M-g n`으로 남은 진단이 없는지 확인
3. [테스트 실행하기](/scenarios/test/)로 넘어가 `C-c g t`

# 00. 학습 가이드 (필수!)

> **이 문서를 먼저 읽고, 순서대로 학습할 것!**
> 이 문서를 건너뛰면 나중에 실수한다.

---

## 🚨 지시서 만들기 전 필수! (건너뛰지 마!)

지시서 작성 전에 **반드시 view 도구로** 템플릿 읽을 것:

```
ai_bridge/templates/BIGSTEP_TEMPLATE.md
```

```
❌ "대충 기억나니까 바로 작성" 
→ 실수 100% (실제로 BIG_101에서 발생)
→ Shell 순서 확인 빠뜨림 → 탭 클릭시 엉뚝한 페이지

✅ "view로 템플릿 열고 체크리스트 따라가기"
→ 실수 방지
```

**템플릿 안 읽고 지시서 쓰면 또 실수한다!**

---

## ⚠️ 학습 체크리스트

아래 체크리스트를 **순서대로** 완료할 것:

### 1단계: 필수 학습 (반드시!)
- [ ] `01_PRINCIPLES.md` 전체 읽기
- [ ] `02_GUIDE.md` 전체 읽기
- [ ] `03_WORKFLOW.md` 전체 읽기

### 2단계: 중요 패턴 학습
- [ ] `04_PATTERNS.md` 전체 읽기
- [ ] `05_GO_ROUTER_PATTERNS.md` 전체 읽기

### 3단계: 참고 자료
- [ ] `06_HISTORY.md` 훑어보기
- [ ] `07_VISION_AI_LIMITS.md` 훑어보기
- [ ] `08_CLAUDE_LIMITATIONS.md` 읽기 ⭐ **자각 필수!**
- [ ] `knowhow/` 폴더 내용 확인

### 4단계: 템플릿 확인
- [ ] `ai_bridge/templates/BIGSTEP_TEMPLATE.md` 읽기

---

## 🚨 자주 빠뜨리는 것들 (주의!)

### 1. 빅스텝 번호 확인 안 함
```
❌ 잘못: "BIG_002로 만들게요"
✅ 올바름: bigstep/ 폴더에서 마지막 번호 확인 후 +1

확인 방법:
ai_bridge/bigstep/ 폴더 → 마지막 BIG_XXX 번호 확인
```

### 2. 진입 경로 전체 확인 안 함
```
❌ 잘못: 라우터만 추가하고 끝
✅ 올바름: Shell의 _pages, destinations 순서까지 확인

예시:
- app_router.dart에 /my-books 추가 ✅
- StudentShell._pages 배열에 추가 ✅
- StudentShell.destinations 순서 확인 ❌ ← 여기서 버그!
```

### 3. 지시서 만들기 전 템플릿 안 읽음
```
❌ 잘못: 상상으로 지시서 작성
✅ 올바름: BIGSTEP_TEMPLATE.md 먼저 읽고 작성

템플릿 위치: ai_bridge/templates/BIGSTEP_TEMPLATE.md
```

### 4. 실제 코드 안 보고 지시서 작성
```
❌ 잘못: "버튼 추가해줘" (모호함)
✅ 올바름: view 도구로 파일 열어서 줄 번호까지 특정

예시:
- 파일: lib/features/student/student_shell.dart
- 위치: 27줄 _pages 배열
- 기존 코드: [StudentHomePage(), StudentLessonsPage(), ...]
- 새 코드: [..., MyBooksPage()]
```

### 5. Shell 수정 시 순서 불일치
```
IndexedStack 기반 Shell에서:

_pages 배열 순서 = destinations 순서 = _pageTitles 순서

세 개가 안 맞으면 탭 클릭 시 엉뚱한 페이지 나옴!
```

---

## 📋 지시서 작성 전 필수 확인

지시서 만들기 전에 **반드시** 확인:

```
1. ai_bridge/bigstep/ 폴더에서 마지막 번호 확인
2. ai_bridge/templates/BIGSTEP_TEMPLATE.md 읽기
3. 수정할 파일 view 도구로 직접 열어보기
4. 진입 경로 전체 파악:
   - 라우터 (app_router.dart)
   - Shell (_pages, destinations, _pageTitles)
   - 네비게이션 버튼 (context.push 등)
5. 삭제/추가할 코드 구체적으로 작성
```

---

## 🔄 작업 플로우

```
1. 이 파일(00) 읽기
        ↓
2. 01~03 필수 학습
        ↓
3. 04~07 필요한 것 학습
        ↓
4. 작업 시작 전:
   - bigstep/ 마지막 번호 확인
   - templates/BIGSTEP_TEMPLATE.md 읽기
   - 실제 코드 view로 확인
        ↓
5. 지시서 작성 또는 작업 수행
```

---

## 📁 폴더 구조 (참고)

```
ai_bridge/
├── learning/           # 학습 자료 (여기!)
│   ├── 00_LEARNING_GUIDE.md  # 이 파일
│   ├── 01_PRINCIPLES.md
│   ├── 02_GUIDE.md
│   ├── 03_WORKFLOW.md
│   ├── 04_PATTERNS.md
│   ├── 05_GO_ROUTER_PATTERNS.md
│   ├── 06_HISTORY.md
│   ├── 07_VISION_AI_LIMITS.md
│   ├── 08_CLAUDE_LIMITATIONS.md  # Claude 약점 자각
│   └── knowhow/
│
├── templates/          # 템플릿
│   └── BIGSTEP_TEMPLATE.md
│
├── bigstep/            # 작업 지시서
│   └── BIG_XXX_*.md
│
├── logs/               # Sonnet 실행 로그
├── report/             # 보고서
└── ...
```

---

## ✅ 학습 완료 확인

아래 질문에 답할 수 있으면 학습 완료:

1. CP의 핵심 철학 3가지는?
2. Opus와 Sonnet의 역할 분담은?
3. go_router에서 네비게이션 방법은?
4. 빅스텝 지시서 작성 전 확인할 것 5가지는?
5. Shell 수정 시 순서 맞춰야 하는 3가지는?
6. Claude의 핵심 약점은? 어려운 문제에서 어떻게 해야 하나?

---

**이제 01_PRINCIPLES.md부터 순서대로 읽어!**

---

## 🆕 learning 폴더에 새 파일 추가할 때

새로운 학습 내용을 추가할 경우 **반드시** 이 파일(00_LEARNING_GUIDE.md)도 함께 업데이트할 것!

### 추가 절차

```
1. 새 파일 생성 (번호 부여)
   - 기존 번호 확인 → 적절한 위치에 번호 부여
   - 예: 08_NEW_TOPIC.md

2. 이 파일(00) 업데이트
   - "📁 폴더 구조" 섹션에 새 파일 추가
   - "학습 체크리스트"에 해당 단계 추가
   - 필요시 "자주 빠뜨리는 것들"에 관련 주의사항 추가

3. 중요도 판단
   - ⭐⭐⭐ 필수: 1~3단계에 추가
   - ⭐⭐ 중요: 2단계에 추가  
   - ⭐ 참고: 3단계에 추가
   - knowhow/: 특정 주제 노하우
```

### 예시

```
새 파일: 08_AWS_PATTERNS.md (AWS 관련 패턴)

→ 이 파일에서 업데이트할 곳:
1. 폴더 구조 섹션에 추가
2. 학습 체크리스트 2단계에 추가 (중요 패턴이므로)
3. 필요시 주의사항 섹션에 AWS 관련 실수 추가
```

### 왜 중요한가?

```
❌ 새 파일만 추가하고 00 업데이트 안 함
→ 다음 Claude가 새 파일 존재 모름
→ 학습 누락 → 같은 실수 반복

✅ 새 파일 추가 + 00 업데이트
→ 다음 Claude가 00부터 읽음
→ 새 파일도 학습 → 실수 방지
```

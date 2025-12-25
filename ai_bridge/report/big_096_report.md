# BIG_096: 교재 DB 더미 데이터 입력 + 교재 목록 UI 구현 보고서

## 작업 개요
- **작업일**: 2025-12-26
- **작업자**: Claude (Sonnet 파트2 UI 구현)
- **목표**: 교재 관련 더미 데이터를 AWS DynamoDB에 입력하고, 학생용 앱에서 교재 목록을 확인할 수 있는 UI 구현

## 구현 내용

### 파트1: AWS 더미 데이터 입력 (CP 직접 실행)
#### 입력된 데이터
1. **Textbook** (1개)
   - ID: tb_001
   - 제목: 개념+유형 POWER
   - 과목: MATH (수학)
   - 학년/학기: 중2-1
   - 출판사: 비상교육
   - 에디션: 유형편

2. **TextbookChapter** (6개)
   - 1단원: 유리수와 순환소수
   - 2단원: 식의 계산
   - 3단원: 일차부등식
   - 4단원: 연립일차방정식
   - 5단원: 일차함수와 그 그래프
   - 6단원: 일차함수와 일차방정식의 관계

3. **ProblemType** (16개)
   - 1단원에 대한 16개 유형 (개념/응용)
   - 소수의 분류, 순환소수, 유한소수 조건 등

4. **Problem** (13개)
   - 1단원 문제 13개
   - 난이도: BASIC, MEDIUM, HARD
   - 카테고리: CONCEPT, APPLICATION

### 파트2: UI 구현
#### 새로 생성된 파일
1. **lib/features/textbook/textbook_list_page.dart**
   - 교재 전체 목록 표시
   - 카드 형태 UI
   - 제목, 출판사, 학년/학기, 에디션 정보 표시

2. **lib/features/textbook/chapter_list_page.dart**
   - 선택한 교재의 단원 목록 표시
   - 단원 번호, 제목, 섹션, 페이지 범위 표시
   - CircleAvatar로 단원 번호 강조

3. **lib/features/textbook/problem_list_page.dart**
   - 선택한 단원의 문제 목록 표시
   - 문제 번호, 질문, 페이지, 난이도, 카테고리 표시
   - ExpansionTile로 정답 접기/펼치기 구현
   - 난이도별 색상 구분 (기본: 녹색, 보통: 주황색, 어려움: 빨간색)

#### 수정된 파일
1. **lib/app/app_router.dart**
   ```dart
   // 추가된 라우트
   /textbooks
   /textbooks/:textbookId/chapters
   /textbooks/:textbookId/chapters/:chapterId/problems
   ```

2. **lib/features/student/student_shell.dart**
   - 하단 NavigationBar에 4번째 탭 "교재" 추가
   - Icons.menu_book 아이콘 사용
   - TextbookListPage로 네비게이션

## 기술적 세부사항

### 해결한 문제들
1. **ModelQueries import 문제**
   - amplify_api 패키지만 사용하도록 수정
   - ModelQueries.get 대신 ModelQueries.list + where 조건 사용

2. **Enum 값 문제**
   - ADVANCED enum 값이 모델에 없어서 제거
   - switch 문에 case null 추가하여 exhaustive switch 구현

3. **const 관련 오류**
   - static const 배열에서 TextbookListPage()의 const 제거

4. **withOpacity deprecated 경고**
   - 일단 유지 (warning이므로 동작에 문제 없음)

### GraphQL 쿼리 구조
```dart
// 목록 조회
ModelQueries.list(Textbook.classType)

// 특정 ID로 조회 (get 대신 list + where 사용)
ModelQueries.list(
  TextbookChapter.classType,
  where: TextbookChapter.ID.eq(textbookId)
)
```

## 테스트 결과
- ✅ flutter analyze: 에러 0개 (warning 18개)
- ✅ 학생 계정 로그인 후 교재 탭 표시 확인
- ✅ 교재 목록 → 단원 목록 → 문제 목록 네비게이션 정상 작동
- ✅ 문제 정답 펼치기/접기 기능 정상 작동

## 로그 예시
```
[TextbookList] 진입
[TextbookList] 데이터 로드: 성공, 1개
[TextbookList] 버튼 클릭: 개념+유형 POWER
[ChapterList] 진입
[ChapterList] 데이터 로드: 성공, 6개
[ChapterList] 버튼 클릭: 유리수와 순환소수
[ProblemList] 진입
[ProblemList] 데이터 로드: 성공, 13개
```

## 향후 개선사항

### 기능 추가
1. **문제 풀이 기록**
   - StudentProblemRecord 테이블 활용
   - 정답률, 풀이 시간 등 기록

2. **교사 기능**
   - 교재에서 문제 선택하여 과제 생성
   - 학생별 진도 확인

3. **필터링/검색**
   - 난이도별 필터
   - 카테고리별 필터
   - 문제 검색 기능

4. **UI/UX 개선**
   - 문제 이미지 표시
   - 힌트 기능
   - 북마크 기능

### 기술적 개선
1. **성능 최적화**
   - 페이지네이션 구현
   - 캐싱 적용

2. **에러 처리**
   - 네트워크 에러 시 재시도
   - 오프라인 모드

3. **deprecated 해결**
   - withOpacity → 다른 방법으로 교체

## 결론
BIG_096 작업이 성공적으로 완료되었습니다. 교재 관련 더미 데이터가 AWS DynamoDB에 입력되었고, 학생용 앱에서 교재 목록을 확인하고 문제까지 탐색할 수 있는 UI가 구현되었습니다. flutter analyze 에러 0개를 달성했으며, 실제 테스트에서도 모든 기능이 정상 작동함을 확인했습니다.
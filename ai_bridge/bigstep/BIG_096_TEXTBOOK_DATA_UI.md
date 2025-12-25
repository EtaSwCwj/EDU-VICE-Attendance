# BIG_096: 교재 DB 더미 데이터 입력 + 교재 목록 UI

> 생성일: 2025-12-25
> 목표: 더미 데이터 입력 후 앱에서 교재 목록 확인

---

## ⚠️ CP 직접 실행 파트

> AWS CLI 명령은 인증 필요해서 CP가 직접 실행

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 더미 데이터: ai_bridge/phase3/textbook_data/개념유형_중2_1_유형편.json
- 테이블:
  - Textbook-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
  - TextbookChapter-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
  - ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
  - Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- DB에 교재 1권, 단원 6개, 유형 16개, 문제 13개 저장
- 앱에서 교재 목록 조회 가능
- 교재 클릭 시 단원/문제 목록 확인 가능

### 테스트 시나리오
```
1. 앱 실행 → 교재 탭 진입
2. "개념+유형 POWER 중2-1" 교재 표시 확인
3. 교재 클릭 → 단원 목록 6개 확인
4. 단원 클릭 → 문제 목록 확인
```

---

## 파트 1: CP 직접 실행 (더미 데이터 입력)

### 1-1. Textbook 입력

```bash
aws dynamodb put-item --table-name Textbook-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{
  "id": {"S": "tb_001"},
  "title": {"S": "개념+유형 POWER"},
  "subject": {"S": "MATH"},
  "grade": {"S": "중2"},
  "semester": {"S": "1"},
  "publisher": {"S": "비상교육"},
  "edition": {"S": "유형편"},
  "publishYear": {"N": "2024"},
  "totalPages": {"N": "110"},
  "isVerified": {"BOOL": true},
  "createdAt": {"S": "2025-12-25T00:00:00.000Z"},
  "updatedAt": {"S": "2025-12-25T00:00:00.000Z"},
  "__typename": {"S": "Textbook"}
}'
```

### 1-2. TextbookChapter 입력 (6개)

```bash
# 1단원
aws dynamodb put-item --table-name TextbookChapter-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{
  "id": {"S": "ch_001"},
  "textbookId": {"S": "tb_001"},
  "section": {"S": "I. 수와 식의 계산"},
  "number": {"N": "1"},
  "title": {"S": "유리수와 순환소수"},
  "startPage": {"N": "4"},
  "endPage": {"N": "16"},
  "createdAt": {"S": "2025-12-25T00:00:00.000Z"},
  "updatedAt": {"S": "2025-12-25T00:00:00.000Z"},
  "__typename": {"S": "TextbookChapter"}
}'

# 2단원
aws dynamodb put-item --table-name TextbookChapter-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{
  "id": {"S": "ch_002"},
  "textbookId": {"S": "tb_001"},
  "section": {"S": "I. 수와 식의 계산"},
  "number": {"N": "2"},
  "title": {"S": "식의 계산"},
  "startPage": {"N": "20"},
  "endPage": {"N": "36"},
  "createdAt": {"S": "2025-12-25T00:00:00.000Z"},
  "updatedAt": {"S": "2025-12-25T00:00:00.000Z"},
  "__typename": {"S": "TextbookChapter"}
}'

# 3단원
aws dynamodb put-item --table-name TextbookChapter-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{
  "id": {"S": "ch_003"},
  "textbookId": {"S": "tb_001"},
  "section": {"S": "II. 부등식과 연립방정식"},
  "number": {"N": "3"},
  "title": {"S": "일차부등식"},
  "startPage": {"N": "40"},
  "endPage": {"N": "54"},
  "createdAt": {"S": "2025-12-25T00:00:00.000Z"},
  "updatedAt": {"S": "2025-12-25T00:00:00.000Z"},
  "__typename": {"S": "TextbookChapter"}
}'

# 4단원
aws dynamodb put-item --table-name TextbookChapter-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{
  "id": {"S": "ch_004"},
  "textbookId": {"S": "tb_001"},
  "section": {"S": "II. 부등식과 연립방정식"},
  "number": {"N": "4"},
  "title": {"S": "연립일차방정식"},
  "startPage": {"N": "58"},
  "endPage": {"N": "77"},
  "createdAt": {"S": "2025-12-25T00:00:00.000Z"},
  "updatedAt": {"S": "2025-12-25T00:00:00.000Z"},
  "__typename": {"S": "TextbookChapter"}
}'

# 5단원
aws dynamodb put-item --table-name TextbookChapter-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{
  "id": {"S": "ch_005"},
  "textbookId": {"S": "tb_001"},
  "section": {"S": "III. 일차함수"},
  "number": {"N": "5"},
  "title": {"S": "일차함수와 그 그래프"},
  "startPage": {"N": "80"},
  "endPage": {"N": "96"},
  "createdAt": {"S": "2025-12-25T00:00:00.000Z"},
  "updatedAt": {"S": "2025-12-25T00:00:00.000Z"},
  "__typename": {"S": "TextbookChapter"}
}'

# 6단원
aws dynamodb put-item --table-name TextbookChapter-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{
  "id": {"S": "ch_006"},
  "textbookId": {"S": "tb_001"},
  "section": {"S": "III. 일차함수"},
  "number": {"N": "6"},
  "title": {"S": "일차함수와 일차방정식의 관계"},
  "startPage": {"N": "100"},
  "endPage": {"N": "110"},
  "createdAt": {"S": "2025-12-25T00:00:00.000Z"},
  "updatedAt": {"S": "2025-12-25T00:00:00.000Z"},
  "__typename": {"S": "TextbookChapter"}
}'
```

### 1-3. ProblemType 입력 (1단원 유형 16개)

```bash
# 유형 1-8
aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_001"},"chapterId":{"S":"ch_001"},"number":{"N":"1"},"title":{"S":"소수의 분류"},"category":{"S":"CONCEPT"},"description":{"S":"유한소수와 무한소수 구분하기"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_002"},"chapterId":{"S":"ch_001"},"number":{"N":"2"},"title":{"S":"순환소수와 순환마디"},"category":{"S":"CONCEPT"},"description":{"S":"순환소수의 순환마디 찾기"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_003"},"chapterId":{"S":"ch_001"},"number":{"N":"3"},"title":{"S":"소수점 아래 n번째 자리의 숫자 구하기"},"category":{"S":"APPLICATION"},"description":{"S":"순환마디를 이용하여 특정 자리 숫자 찾기"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_004"},"chapterId":{"S":"ch_001"},"number":{"N":"4"},"title":{"S":"유한소수로 나타낼 수 있는 분수"},"category":{"S":"CONCEPT"},"description":{"S":"분모의 소인수 조건 확인"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_005"},"chapterId":{"S":"ch_001"},"number":{"N":"5"},"title":{"S":"B/A × x를 유한소수가 되도록 하는 x의 값 구하기"},"category":{"S":"APPLICATION"},"description":{"S":"분모 조건 만족하는 미지수 찾기"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_006"},"chapterId":{"S":"ch_001"},"number":{"N":"6"},"title":{"S":"두 분수를 모두 유한소수가 되도록 하는 미지수의 값 구하기"},"category":{"S":"APPLICATION"},"description":{"S":"두 조건 동시 만족"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_007"},"chapterId":{"S":"ch_001"},"number":{"N":"7"},"title":{"S":"B/(A×x)를 유한소수가 되도록 하는 x의 값 구하기"},"category":{"S":"APPLICATION"},"description":{"S":"분모에 미지수가 있는 경우"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_008"},"chapterId":{"S":"ch_001"},"number":{"N":"8"},"title":{"S":"기약분수의 분자가 주어질 때, 유한소수가 되도록 하는 미지수의 값 구하기"},"category":{"S":"APPLICATION"},"description":{"S":"기약분수 조건 추가"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

# 유형 9-16
aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_009"},"chapterId":{"S":"ch_001"},"number":{"N":"9"},"title":{"S":"순환소수가 되도록 하는 미지수의 값 구하기"},"category":{"S":"APPLICATION"},"description":{"S":"무한소수 조건 찾기"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_010"},"chapterId":{"S":"ch_001"},"number":{"N":"10"},"title":{"S":"순환소수를 분수로 나타내기 (1)"},"category":{"S":"CONCEPT"},"description":{"S":"순환소수 → 분수 변환 기본"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_011"},"chapterId":{"S":"ch_001"},"number":{"N":"11"},"title":{"S":"순환소수를 분수로 나타내기 (2)"},"category":{"S":"APPLICATION"},"description":{"S":"순환소수 → 분수 변환 심화"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_012"},"chapterId":{"S":"ch_001"},"number":{"N":"12"},"title":{"S":"분수를 소수로 바르게 나타내기"},"category":{"S":"CONCEPT"},"description":{"S":"분수 → 소수 변환"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_013"},"chapterId":{"S":"ch_001"},"number":{"N":"13"},"title":{"S":"순환소수를 포함한 식의 계산"},"category":{"S":"APPLICATION"},"description":{"S":"순환소수 연산"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_014"},"chapterId":{"S":"ch_001"},"number":{"N":"14"},"title":{"S":"순환소수에 적당한 수를 곱하여 자연수 또는 유한소수 만들기"},"category":{"S":"APPLICATION"},"description":{"S":"순환 제거 조건 찾기"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_015"},"chapterId":{"S":"ch_001"},"number":{"N":"15"},"title":{"S":"순환소수의 대소 관계"},"category":{"S":"APPLICATION"},"description":{"S":"순환소수 크기 비교"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'

aws dynamodb put-item --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pt_016"},"chapterId":{"S":"ch_001"},"number":{"N":"16"},"title":{"S":"유리수와 소수의 관계"},"category":{"S":"CONCEPT"},"description":{"S":"유리수 ↔ 소수 관계 이해"},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"ProblemType"}}'
```

### 1-4. Problem 입력 (문제 13개)

```bash
aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_001"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_001"},"page":{"N":"6"},"number":{"S":"1"},"difficulty":{"S":"BASIC"},"category":{"S":"CONCEPT"},"question":{"S":"다음 보기 중 유한소수인 것의 개수는?"},"answer":{"S":"③"},"concepts":{"L":[{"S":"유한소수"},{"S":"무한소수"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_002"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_001"},"page":{"N":"6"},"number":{"S":"2"},"difficulty":{"S":"BASIC"},"category":{"S":"CONCEPT"},"question":{"S":"다음 분수 중 소수로 나타냈을 때, 무한소수가 되는 것은?"},"answer":{"S":"②"},"concepts":{"L":[{"S":"무한소수"},{"S":"분수변환"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_003"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_001"},"page":{"N":"6"},"number":{"S":"3"},"difficulty":{"S":"MEDIUM"},"category":{"S":"CONCEPT"},"question":{"S":"다음 보기 중 옳지 않은 것을 모두 고르시오."},"answer":{"S":"ㄴ, ㄹ"},"concepts":{"L":[{"S":"유한소수"},{"S":"무한소수"},{"S":"순환소수"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_004"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_002"},"page":{"N":"6"},"number":{"S":"4"},"difficulty":{"S":"BASIC"},"category":{"S":"CONCEPT"},"question":{"S":"다음 중 순환소수와 순환마디가 바르게 연결된 것은?"},"answer":{"S":"⑤"},"concepts":{"L":[{"S":"순환소수"},{"S":"순환마디"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_005"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_002"},"page":{"N":"6"},"number":{"S":"5"},"difficulty":{"S":"BASIC"},"category":{"S":"CONCEPT"},"question":{"S":"다음 분수 중 소수로 나타냈을 때, 순환마디가 나머지 넷과 다른 하나는?"},"answer":{"S":"②"},"concepts":{"L":[{"S":"순환마디"},{"S":"분수변환"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_006"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_003"},"page":{"N":"6"},"number":{"S":"6"},"difficulty":{"S":"MEDIUM"},"category":{"S":"APPLICATION"},"question":{"S":"두 분수 5/11과 4/13을 각각 소수로 나타냈을 때, 순환마디를 이루는 숫자의 개수를 각각 a개, b개라고 하자. 이때 a+b의 값을 구하시오."},"answer":{"S":"8"},"concepts":{"L":[{"S":"순환마디"},{"S":"순환마디길이"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_007"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_002"},"page":{"N":"7"},"number":{"S":"7"},"difficulty":{"S":"BASIC"},"category":{"S":"CONCEPT"},"question":{"S":"다음 중 순환소수의 표현이 옳은 것은?"},"answer":{"S":"④"},"concepts":{"L":[{"S":"순환소수표현"},{"S":"순환마디표기"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_008"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_012"},"page":{"N":"7"},"number":{"S":"8"},"difficulty":{"S":"BASIC"},"category":{"S":"CONCEPT"},"question":{"S":"분수 18/55을 순환소수로 바르게 나타낸 것은?"},"answer":{"S":"④"},"concepts":{"L":[{"S":"분수변환"},{"S":"순환소수표현"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_009"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_003"},"page":{"N":"7"},"number":{"S":"9"},"difficulty":{"S":"HARD"},"category":{"S":"APPLICATION"},"question":{"S":"0부터 9까지의 숫자를 각 음에 대응시켜 분수를 소수로 나타내어 연주하는 앱 문제"},"answer":{"S":"②"},"concepts":{"L":[{"S":"순환소수"},{"S":"응용"},{"S":"융합"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_010"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_003"},"page":{"N":"7"},"number":{"S":"10"},"difficulty":{"S":"MEDIUM"},"category":{"S":"APPLICATION"},"question":{"S":"순환소수 0.05273의 소수점 아래 100번째 자리의 숫자를 구하시오."},"answer":{"S":"7"},"concepts":{"L":[{"S":"순환마디"},{"S":"나머지연산"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_011"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_003"},"page":{"N":"7"},"number":{"S":"11"},"difficulty":{"S":"MEDIUM"},"category":{"S":"APPLICATION"},"question":{"S":"분수 4/37을 소수로 나타낼 때, 소수점 아래 35번째 자리의 숫자를 구하시오. (서술형)"},"answer":{"S":"0"},"concepts":{"L":[{"S":"순환마디"},{"S":"서술형"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_012"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_003"},"page":{"N":"7"},"number":{"S":"12"},"difficulty":{"S":"HARD"},"category":{"S":"APPLICATION"},"question":{"S":"분수 11/13을 소수로 나타낼 때, 소수점 아래 n번째 자리의 숫자를 an이라고 하자. 이때 a1+a2+...+a14의 값을 구하시오."},"answer":{"S":"63"},"concepts":{"L":[{"S":"순환마디"},{"S":"수열합"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'

aws dynamodb put-item --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --item '{"id":{"S":"pr_013"},"textbookId":{"S":"tb_001"},"chapterId":{"S":"ch_001"},"typeId":{"S":"pt_003"},"page":{"N":"7"},"number":{"S":"13"},"difficulty":{"S":"MEDIUM"},"category":{"S":"APPLICATION"},"question":{"S":"순환소수 2.3714에서 소수점 아래 50번째 자리의 숫자를 구하시오."},"answer":{"S":"1"},"concepts":{"L":[{"S":"순환마디"},{"S":"나머지연산"}]},"createdAt":{"S":"2025-12-25T00:00:00.000Z"},"updatedAt":{"S":"2025-12-25T00:00:00.000Z"},"__typename":{"S":"Problem"}}'
```

### 1-5. 데이터 확인

```bash
# Textbook 확인
aws dynamodb scan --table-name Textbook-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --query "Count"

# Chapter 확인
aws dynamodb scan --table-name TextbookChapter-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --query "Count"

# ProblemType 확인
aws dynamodb scan --table-name ProblemType-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --query "Count"

# Problem 확인
aws dynamodb scan --table-name Problem-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2 --query "Count"
```

**예상 결과:**
- Textbook: 1
- TextbookChapter: 6
- ProblemType: 16
- Problem: 13

---

## 파트 2: Sonnet 작업 (교재 목록 UI)

> CP: 데이터 입력 완료 후 아래 메시지로 Sonnet 호출

### Sonnet 호출 메시지

```
BIG_096 파트2: 교재 목록 UI 만들기

## 작업 내용

### 1. 새 파일 생성: lib/features/textbook/textbook_list_page.dart

교재 목록 페이지:
- Textbook 전체 조회 (Amplify.API.query)
- 카드 형태로 표시
- 표시 정보: 제목, 출판사, 학년/학기, 에디션
- 클릭 시 단원 목록 페이지로 이동

### 2. 새 파일 생성: lib/features/textbook/chapter_list_page.dart

단원 목록 페이지:
- textbookId로 TextbookChapter 조회
- 리스트 형태로 표시
- 표시 정보: 섹션, 단원번호, 제목, 페이지 범위
- 클릭 시 문제 목록 페이지로 이동

### 3. 새 파일 생성: lib/features/textbook/problem_list_page.dart

문제 목록 페이지:
- chapterId로 Problem 조회
- 리스트 형태로 표시
- 표시 정보: 페이지, 문제번호, 난이도 칩, 카테고리 칩
- 정답은 접어서 표시 (펼치면 보임)

### 4. 라우터 등록: lib/app/app_router.dart

추가할 라우트:
- /textbooks → TextbookListPage
- /textbooks/:textbookId/chapters → ChapterListPage
- /textbooks/:textbookId/chapters/:chapterId/problems → ProblemListPage

### 5. StudentShell 탭 추가: lib/features/student/student_shell.dart

하단 탭에 "교재" 탭 추가:
- 아이콘: Icons.menu_book
- 누르면 TextbookListPage로 이동

## 테스트

작업 완료 후:
```bash
flutter analyze
```

## 로그 위치

ai_bridge/logs/big_096_part2.log
```

---

## 완료 조건

1. 파트1: 더미 데이터 입력 완료 (CP)
2. 파트2: UI 구현 완료 (Sonnet)
3. flutter analyze 에러 0개
4. 앱에서 교재 목록 → 단원 → 문제 확인 가능
5. CP 테스트 완료

---

## 보고서

ai_bridge/report/big_096_report.md

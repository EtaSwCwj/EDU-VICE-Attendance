# TASK_003: 버그픽스 + 테스트 준비

> **작성자**: 윈 선임 (Opus)  
> **작성일**: 2025-12-20  
> **담당**: 윈 후임 (Sonnet)  
> **원칙**: 묻지 말고 끝까지 진행. 로그 필수. 앱 종료 = 테스트 끝.

---

## 📋 작업 목록

### 1. 테스트 계정 삭제 (maknae12@gmail.com)

**Cognito에서 삭제:**
```bash
# User Pool ID 확인
aws cognito-idp list-user-pools --max-results 10 --query "UserPools[*].[Id,Name]" --output table

# 유저 삭제 (위에서 확인한 User Pool ID 사용)
aws cognito-idp admin-delete-user --user-pool-id [USER_POOL_ID] --username maknae12@gmail.com
```

**DynamoDB에서 삭제:**
```bash
# 테이블 이름 확인
aws dynamodb list-tables --query "TableNames[?contains(@, 'AppUser')]" --output table

# 해당 유저 조회
aws dynamodb scan --table-name [AppUser-테이블명] --filter-expression "email = :email" --expression-attribute-values '{":email":{"S":"maknae12@gmail.com"}}'

# 조회된 id로 삭제
aws dynamodb delete-item --table-name [AppUser-테이블명] --key '{"id":{"S":"[조회된ID]"}}'
```

**또는 AWS Console에서 직접 삭제해도 됨.**

---

### 2. 생년월일 입력 UX 개선

**파일**: `lib/features/auth/register_page.dart`

**문제**: 
- 캘린더 피커만 있음
- 1980년생이면 20년 넘게 스크롤해야 함
- 월 선택도 클릭 여러 번 필요

**수정 내용**:

#### 2-1. import 추가 (파일 상단)
```dart
import 'package:flutter/services.dart';
```

#### 2-2. 생년월일 TextFormField 수정

**찾아서:**
```dart
// 생년월일
TextFormField(
  controller: _birthDateController,
  decoration: const InputDecoration(
    labelText: '생년월일',
    hintText: 'YYYY-MM-DD',
    prefixIcon: Icon(Icons.calendar_today),
    border: OutlineInputBorder(),
  ),
  readOnly: true,
  onTap: _selectBirthDate,
),
```

**이걸로 교체:**
```dart
// 생년월일 - 직접 입력 + 캘린더 버튼
TextFormField(
  controller: _birthDateController,
  decoration: InputDecoration(
    labelText: '생년월일',
    hintText: 'YYYY-MM-DD (예: 1990-06-15)',
    prefixIcon: const Icon(Icons.calendar_today),
    border: const OutlineInputBorder(),
    suffixIcon: IconButton(
      icon: const Icon(Icons.date_range),
      onPressed: _selectBirthDate,
      tooltip: '달력에서 선택',
    ),
  ),
  keyboardType: TextInputType.datetime,
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
    LengthLimitingTextInputFormatter(10),
    _DateInputFormatter(),
  ],
  validator: _validateBirthDate,
),
```

#### 2-3. _selectBirthDate 함수 수정

**찾아서:**
```dart
Future<void> _selectBirthDate() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime(2000, 1, 1),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
    locale: const Locale('ko', 'KR'),
  );
  if (picked != null) {
    setState(() {
      _birthDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }
}
```

**이걸로 교체:**
```dart
Future<void> _selectBirthDate() async {
  safePrint('[RegisterPage] Opening birth date picker');
  
  // 현재 입력된 값이 있으면 그걸로 시작, 없으면 2000년
  DateTime initialDate = DateTime(2000, 1, 1);
  if (_birthDateController.text.isNotEmpty) {
    try {
      final parts = _birthDateController.text.split('-');
      if (parts.length == 3) {
        initialDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (e) {
      safePrint('[RegisterPage] Could not parse existing date: $e');
    }
  }
  
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1920),
    lastDate: DateTime.now(),
    locale: const Locale('ko', 'KR'),
    initialDatePickerMode: DatePickerMode.year,  // 연도 선택부터 시작!
    helpText: '생년월일 선택',
    cancelText: '취소',
    confirmText: '확인',
  );
  
  if (picked != null) {
    safePrint('[RegisterPage] Birth date selected: $picked');
    setState(() {
      _birthDateController.text = 
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }
}
```

#### 2-4. 새 함수/클래스 추가 (클래스 하단, 마지막 } 전에)

```dart
/// 생년월일 검증
String? _validateBirthDate(String? value) {
  if (value == null || value.isEmpty) {
    return null; // 선택 필드라 비어있어도 OK
  }
  
  // 형식 체크
  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!regex.hasMatch(value)) {
    return 'YYYY-MM-DD 형식으로 입력해주세요';
  }
  
  // 유효한 날짜인지 체크
  try {
    final parts = value.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    
    if (year < 1900 || year > DateTime.now().year) {
      return '올바른 연도를 입력해주세요';
    }
    if (month < 1 || month > 12) {
      return '올바른 월을 입력해주세요';
    }
    if (day < 1 || day > 31) {
      return '올바른 일을 입력해주세요';
    }
    
    final date = DateTime(year, month, day);
    if (date.isAfter(DateTime.now())) {
      return '미래 날짜는 입력할 수 없습니다';
    }
  } catch (e) {
    return '올바른 날짜를 입력해주세요';
  }
  
  return null;
}
```

#### 2-5. 파일 맨 하단에 클래스 추가 (RegisterPage 클래스 바깥)

```dart
/// 생년월일 자동 포맷터 (YYYY-MM-DD)
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 8; i++) {
      if (i == 4 || i == 6) buffer.write('-');
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
```

---

## ✅ 완료 체크리스트

- [ ] maknae12@gmail.com 삭제 (Cognito)
- [ ] maknae12@gmail.com 삭제 (DynamoDB)
- [ ] register_page.dart 수정
- [ ] flutter analyze 에러 없음
- [ ] 앱 빌드 성공
- [ ] 생년월일 직접 타이핑 테스트 (19900615 → 1990-06-15)
- [ ] 캘린더 연도 선택부터 시작하는지 확인

---

## 📝 완료 보고

작업 끝나면 `C:\github\ai_bridge\task_003_result.md`에 결과 보고서 작성.

```markdown
# TASK_003 완료 보고

**상태**: ✅ 완료 / ❌ 실패

## 삭제된 계정
- maknae12@gmail.com: Cognito ✅ / DynamoDB ✅

## 수정된 파일
- register_page.dart

## 테스트 결과
- flutter analyze: 0 에러
- 생년월일 타이핑: ✅ 작동
- 캘린더 연도 선택: ✅ 작동

## 이슈
- (있으면 작성)
```

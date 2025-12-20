// lib/features/auth/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import '../users/data/repositories/app_user_aws_repository.dart';

/// 회원가입 페이지
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();

  String? _selectedGender;
  bool _isLoading = false;
  bool _needConfirmation = false;
  bool _agreedToTerms = false;
  String? _tempUsername;
  final _confirmationCodeController = TextEditingController();

  final _userRepo = AppUserAwsRepository();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _confirmationCodeController.dispose();
    super.dispose();
  }

  /// 이메일 유효성 검증
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    if (!value.contains('@')) {
      return '유효한 이메일 주소를 입력해주세요';
    }
    return null;
  }

  /// 비밀번호 유효성 검증
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다';
    }
    return null;
  }

  /// 비밀번호 확인 검증
  String? _validatePasswordConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }
    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  /// 이름 검증
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요';
    }
    return null;
  }

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

  /// 생년월일 선택
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

  /// 회원가입 처리
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      safePrint('[RegisterPage] 약관 미동의');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약관에 동의해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();

      safePrint('[RegisterPage] Attempting sign up for: $email');

      // Amplify Auth 회원가입 (username에 이메일 사용)
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
            AuthUserAttributeKey.name: name,
          },
        ),
      );

      safePrint('[RegisterPage] Sign up result: isSignUpComplete=${result.isSignUpComplete}, nextStep=${result.nextStep.signUpStep}');

      if (result.isSignUpComplete) {
        // 즉시 완료된 경우 (이메일 인증 불필요)
        await _createUserInDatabase(email, name);
        if (mounted) {
          _showSuccessAndNavigateToLogin();
        }
      } else {
        // 이메일 인증 필요
        safePrint('[RegisterPage] Email confirmation required');
        setState(() {
          _needConfirmation = true;
          _tempUsername = email;
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      safePrint('[RegisterPage] AuthException: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입 실패: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    } catch (e) {
      safePrint('[RegisterPage] Unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  /// 인증 코드 확인
  Future<void> _confirmSignUp() async {
    final code = _confirmationCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드를 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      safePrint('[RegisterPage] Confirming sign up with code');

      final result = await Amplify.Auth.confirmSignUp(
        username: _tempUsername!,
        confirmationCode: code,
      );

      safePrint('[RegisterPage] Confirm sign up result: isSignUpComplete=${result.isSignUpComplete}');

      if (result.isSignUpComplete) {
        // 인증 완료, User 테이블에 저장
        await _createUserInDatabase(_tempUsername!, _nameController.text.trim());
        if (mounted) {
          _showSuccessAndNavigateToLogin();
        }
      } else {
        safePrint('[RegisterPage] Sign up not completed after confirmation');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증이 완료되지 않았습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } on AuthException catch (e) {
      safePrint('[RegisterPage] Confirm sign up error: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증 실패: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    } catch (e) {
      safePrint('[RegisterPage] Unexpected confirm error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  /// User 테이블에 유저 생성
  Future<void> _createUserInDatabase(String email, String name) async {
    try {
      safePrint('[RegisterPage] Creating user in database: $email');

      // users 그룹에 추가 (자동으로 추가되지 않을 수 있으므로)
      // 주의: 이 작업은 Lambda 트리거나 백엔드에서 수행하는 것이 더 적절함
      // 여기서는 앱에서 직접 User 테이블에 저장만 함

      final user = await _userRepo.createUser(
        cognitoUsername: email,
        email: email,
        name: name,
        birthDate: _birthDateController.text.trim().isEmpty ? null : _birthDateController.text.trim(),
        gender: _selectedGender,
      );

      if (user != null) {
        safePrint('[RegisterPage] User created successfully in database: ${user.id}');
      } else {
        safePrint('[RegisterPage] WARNING: User creation in database failed, but Cognito signup succeeded');
      }
    } catch (e) {
      safePrint('[RegisterPage] Error creating user in database: $e');
      // Cognito 가입은 성공했으므로 계속 진행
    }
  }

  /// 성공 메시지 표시 후 로그인 페이지로 이동
  void _showSuccessAndNavigateToLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('회원가입이 완료되었습니다! 로그인해주세요.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: _needConfirmation ? _buildConfirmationUI() : _buildRegistrationUI(),
    );
  }

  /// 회원가입 입력 UI
  Widget _buildRegistrationUI() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '새 계정 만들기',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 이메일
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일*',
                  hintText: 'example@email.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),

              // 비밀번호
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '비밀번호*',
                  hintText: '8자 이상',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),

              // 비밀번호 확인
              TextFormField(
                controller: _passwordConfirmController,
                decoration: const InputDecoration(
                  labelText: '비밀번호 확인*',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: _validatePasswordConfirm,
              ),
              const SizedBox(height: 16),

              // 이름
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름*',
                  hintText: '홍길동',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),

              // 성별
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: '성별',
                  prefixIcon: Icon(Icons.wc),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('남성')),
                  DropdownMenuItem(value: 'F', child: Text('여성')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // 약관 동의 체크박스
              CheckboxListTile(
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() => _agreedToTerms = value ?? false);
                },
                title: const Text('이용약관 및 개인정보처리방침에 동의합니다'),
                subtitle: TextButton(
                  onPressed: () {
                    safePrint('[RegisterPage] 약관 보기 탭됨');
                    // TODO: 약관 페이지로 이동
                  },
                  child: const Text('약관 보기'),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),

              // 회원가입 버튼
              FilledButton(
                onPressed: _isLoading ? null : _register,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('회원가입', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),

              // 로그인 페이지로 이동
              OutlinedButton(
                onPressed: () => context.go('/login'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('이미 계정이 있으신가요? 로그인', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이메일 인증 코드 입력 UI
  Widget _buildConfirmationUI() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.email, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              '이메일 인증',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '${_tempUsername ?? '이메일'}로 발송된 인증 코드를 입력해주세요.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // 인증 코드 입력
            TextFormField(
              controller: _confirmationCodeController,
              decoration: const InputDecoration(
                labelText: '인증 코드',
                hintText: '123456',
                prefixIcon: Icon(Icons.vpn_key),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),

            // 인증 버튼
            FilledButton(
              onPressed: _isLoading ? null : _confirmSignUp,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('인증 완료', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),

            // 뒤로 가기
            TextButton(
              onPressed: () {
                setState(() {
                  _needConfirmation = false;
                  _confirmationCodeController.clear();
                });
              },
              child: const Text('뒤로 가기'),
            ),
          ],
        ),
      ),
    );
  }
}

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

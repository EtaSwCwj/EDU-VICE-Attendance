// lib/app/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../shared/services/auth_state.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/teacher/teacher_shell.dart';
import '../features/student/student_shell.dart';
import '../features/owner/owner_home_shell.dart';
import '../features/teacher_homework/teacher_homework_page_aws.dart';
import '../features/home/no_academy_shell.dart';
import '../features/home/academy_selector_page.dart';
import '../features/settings/settings_page.dart';
import '../features/invitation/join_by_code_page.dart';
import '../features/invitation/invitation_management_page.dart';
import '../features/supporter/supporter_shell.dart';
import '../features/textbook/textbook_list_page.dart';
import '../features/textbook/chapter_list_page.dart';
import '../features/textbook/problem_list_page.dart';
import '../features/textbook/textbook_analyzer_page.dart';
import '../features/textbook/ocr_test_page.dart';
import '../features/settings/api_key_settings_page.dart';
import '../features/my_books/pages/my_books_page.dart';
import '../features/my_books/pages/book_register_wizard.dart';
import '../features/my_books/pages/book_detail_page.dart';
import '../features/my_books/pages/answer_camera_page.dart';
import '../features/my_books/pages/problem_camera_page.dart';
import '../features/my_books/pages/book_edit_page.dart';
import '../features/my_books/pages/toc_camera_page.dart';

/// 역할 가드 & 홈쉘 분리 라우터
class AppRouter {
  static GoRouter create(AuthState auth) {
    return GoRouter(
      debugLogDiagnostics: false,
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) async {
        final signedIn = auth.isSignedIn;
        final atLogin = state.matchedLocation == '/login';
        final atRegister = state.matchedLocation == '/register';
        final atSplash = state.matchedLocation == '/splash';

        // Splash 화면에서는 redirect하지 않음
        if (atSplash) return null;

        // 회원가입 페이지는 로그인 안 해도 접근 가능
        if (atRegister) return null;

        if (!signedIn && !atLogin) return '/login';
        if (signedIn && atLogin) return '/home';
        return null;
      },
      routes: [
        // 스플래시 (자동 로그인 시도)
        GoRoute(
          path: '/splash',
          builder: (context, state) => _SplashPage(auth: auth),
        ),

        // 로그인
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginPage(),
        ),

        // 회원가입
        GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterPage(),
        ),

        // /home → 역할별 전용 홈셸로 분기
        GoRoute(
          path: '/home',
          builder: (_, __) {
            final user = auth.user;
            final memberships = user?.memberships ?? [];
            final currentMembership = auth.currentMembership;

            // 1. 소속이 없는 경우 → NoAcademyShell
            if (memberships.isEmpty) {
              return const NoAcademyShell();
            }

            // 2. 소속이 여러 개인데 선택하지 않은 경우 → AcademySelectorPage
            if (memberships.length > 1 && currentMembership == null) {
              return const AcademySelectorPage();
            }

            // 3. 소속이 하나거나 이미 선택된 경우 → 역할별 Shell
            final role = currentMembership?.role ?? '';
            switch (role) {
              case 'owner':
                return const OwnerHomeShell(); // 6개 탭
              case 'teacher':
                return const TeacherShell(); // 5개 탭: 홈/수업/학생/숙제/교재
              case 'student':
                return const StudentShell(); // 3개 탭: 홈/수업/숙제
              case 'supporter':
                return const SupporterShell(); // 3개 탭: 홈/학생현황/설정
              default:
                // 알 수 없는 역할 → NoAcademyShell
                return const NoAcademyShell();
            }
          },
        ),

        // ── 설정 페이지 ─────────────────────────────────────────────────
        // API 키 설정 (더 구체적인 경로 먼저!)
        GoRoute(
          path: '/settings/api-key',
          builder: (_, __) => const ApiKeySettingsPage(),
        ),
        // 역할별 설정
        GoRoute(
          path: '/settings/:role',
          builder: (context, state) {
            final role = state.pathParameters['role'] ?? 'student';
            return SettingsPage(role: role);
          },
        ),

        // ── 교사 전용 네임스페이스 예시 ──────────────────────────────────
        GoRoute(
          path: '/teacher/homework',
          // 역할 가드: 교사 외 접근 시 자신의 홈으로 회수
          redirect: (_, __) {
            if ((auth.currentMembership?.role ?? '') != 'teacher') {
              return '/home';
            }
            return null;
          },
          builder: (_, __) => const TeacherHomeworkPageAws(),
        ),

        // ── 초대 관련 라우트 ──────────────────────────────────────────────
        // 초대코드 입력 페이지
        GoRoute(
          path: '/join',
          builder: (_, __) => const JoinByCodePage(),
        ),

        // 초대 관리 페이지 (원장용)
        GoRoute(
          path: '/invitations/:academyId',
          redirect: (_, state) {
            final role = auth.currentMembership?.role ?? '';
            if (role != 'owner') return '/home';
            return null;
          },
          builder: (context, state) {
            final academyId = state.pathParameters['academyId'] ?? '';
            return InvitationManagementPage(academyId: academyId);
          },
        ),
        
        // ── 교재 관련 라우트 ──────────────────────────────────────────────
        // 교재 목록 페이지
        GoRoute(
          path: '/textbooks',
          builder: (_, __) => const TextbookListPage(),
        ),
        
        // 단원 목록 페이지
        GoRoute(
          path: '/textbooks/:textbookId/chapters',
          builder: (context, state) {
            final textbookId = state.pathParameters['textbookId'] ?? '';
            return ChapterListPage(textbookId: textbookId);
          },
        ),
        
        // 문제 목록 페이지
        GoRoute(
          path: '/textbooks/:textbookId/chapters/:chapterId/problems',
          builder: (context, state) {
            final textbookId = state.pathParameters['textbookId'] ?? '';
            final chapterId = state.pathParameters['chapterId'] ?? '';
            return ProblemListPage(
              textbookId: textbookId,
              chapterId: chapterId,
            );
          },
        ),

        // 교재 분석 페이지
        GoRoute(
          path: '/textbook-analyzer',
          builder: (_, __) => const TextbookAnalyzerPage(),
        ),

        // OCR 테스트 페이지
        GoRoute(
          path: '/ocr-test',
          builder: (_, __) => const OcrTestPage(),

        ),
        // ── 내 책 관련 라우트 ──────────────────────────────────────────────
        // 내 책 목록 페이지
        GoRoute(
          path: '/my-books',
          builder: (_, __) => const MyBooksPage(),
        ),
        // 책 등록 위자드
        GoRoute(
          path: '/my-books/register',
          builder: (_, __) => const BookRegisterWizard(),
        ),
        // 책 상세 페이지
        GoRoute(
          path: '/my-books/:bookId',
          builder: (context, state) {
            final bookId = state.pathParameters['bookId'] ?? '';
            return BookDetailPage(bookId: bookId);
          },
        ),
        // 책 수정 페이지
        GoRoute(
          path: '/my-books/:id/edit',
          builder: (context, state) => BookEditPage(
            bookId: state.pathParameters['id']!,
          ),
        ),
        // 정답지 촬영 페이지
        GoRoute(
          path: '/my-books/:bookId/answer-camera',
          builder: (context, state) {
            final bookId = state.pathParameters['bookId'] ?? '';
            return AnswerCameraPage(bookId: bookId);
          },
        ),
        // 문제 촬영 페이지
        GoRoute(
          path: '/my-books/:bookId/problem-camera',
          builder: (context, state) {
            final bookId = state.pathParameters['bookId'] ?? '';
            return ProblemCameraPage(bookId: bookId);
          },
        ),
        // 목차 촬영 페이지
        GoRoute(
          path: '/toc-camera/:bookId',
          builder: (context, state) {
            final bookId = state.pathParameters['bookId'] ?? '';
            return TocCameraPage(bookId: bookId);
          },
        ),

        // 필요 시 /student/*, /owner/* 네임스페이스도 같은 방식으로 확장
      ],
    );
  }
}

/// 스플래시 화면 (자동 로그인 시도)
class _SplashPage extends StatefulWidget {
  final AuthState auth;

  const _SplashPage({required this.auth});

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> {
  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    // 잠시 대기 (스플래시 화면 표시)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      safePrint('[Splash] Attempting auto login...');
      final success = await widget.auth.tryAutoLogin();

      if (!mounted) return;

      if (success) {
        safePrint('[Splash] Auto login successful, navigating to home');
        context.go('/home');
      } else {
        safePrint('[Splash] Auto login failed or disabled, navigating to login');
        context.go('/login');
      }
    } on AuthException catch (e) {
      safePrint('[Splash] AuthException during auto login: ${e.message}');
      if (mounted) {
        context.go('/login');
      }
    } catch (e, stackTrace) {
      safePrint('[Splash] Error during auto login: $e');
      safePrint('[Splash] Stack trace: $stackTrace');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'EDU-VICE',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// EDU-VICE 앱 컬러 팔레트
///
/// 디자인 컨셉: 대치동 학부모 타겟, 고급스럽고 절제된 디자인
/// 민트 컬러는 포인트로만 사용, 전체적으로 화이트/라이트그레이 기반
class AppColors {
  // Primary (포인트 - 아껴서 사용)
  static const Color primary = Color(0xFF2DB4A8);      // 민트/틸
  static const Color primaryLight = Color(0xFF5FCEC4); // 밝은 민트
  static const Color primaryDark = Color(0xFF1E9A8F);  // 어두운 민트

  // Background (기본)
  static const Color background = Color(0xFFFAFAFA);   // 거의 화이트
  static const Color surface = Color(0xFFFFFFFF);      // 카드, 다이얼로그
  static const Color surfaceLight = Color(0xFFF5F7F9); // 연한 그레이 배경

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);  // 거의 블랙
  static const Color textSecondary = Color(0xFF666666); // 회색 텍스트
  static const Color textHint = Color(0xFF999999);     // 힌트 텍스트

  // Accent (상태 표시용)
  static const Color success = Color(0xFF4CAF50);      // 성공/완료
  static const Color warning = Color(0xFFFF9800);      // 경고
  static const Color error = Color(0xFFE53935);        // 에러

  // Divider & Border
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFEEEEEE);
}

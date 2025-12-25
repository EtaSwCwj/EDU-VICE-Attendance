import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// 마름모 패턴 배경
///
/// 명함 우측 상단의 마름모 그라데이션 패턴
/// 용도: 앱바 배경, 스플래시, 로그인 화면 등 포인트로만 사용
class DiamondPattern extends StatelessWidget {
  final double size;
  final Color? color;
  final double opacity;

  const DiamondPattern({
    super.key,
    this.size = 150,
    this.color,
    this.opacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final patternColor = color ?? AppColors.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // 첫 번째 마름모 (가장 어두운)
          Transform.rotate(
            angle: 0.785398, // 45도 (π/4 라디안)
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    patternColor.withValues(alpha: opacity),
                    patternColor.withValues(alpha: opacity * 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // 두 번째 마름모 (중간 밝기)
          Positioned(
            top: size * 0.15,
            left: size * 0.15,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      patternColor.withValues(alpha: opacity * 0.6),
                      patternColor.withValues(alpha: opacity * 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // 세 번째 마름모 (가장 밝음)
          Positioned(
            top: size * 0.3,
            left: size * 0.3,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: size * 0.7,
                height: size * 0.7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      patternColor.withValues(alpha: opacity * 0.4),
                      patternColor.withValues(alpha: opacity * 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 마름모 패턴 배경 (전체 화면 우측 상단)
class DiamondPatternBackground extends StatelessWidget {
  final Widget child;
  final Color? patternColor;
  final double patternOpacity;

  const DiamondPatternBackground({
    super.key,
    required this.child,
    this.patternColor,
    this.patternOpacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 배경
        Positioned.fill(
          child: Container(
            color: AppColors.surface,
          ),
        ),

        // 우측 상단 마름모 패턴
        Positioned(
          top: -50,
          right: -50,
          child: DiamondPattern(
            size: 200,
            color: patternColor,
            opacity: patternOpacity,
          ),
        ),

        // 하단 그라데이션 (선택적)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surface.withValues(alpha: 0.0),
                  AppColors.surfaceLight.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),

        // 컨텐츠
        child,
      ],
    );
  }
}

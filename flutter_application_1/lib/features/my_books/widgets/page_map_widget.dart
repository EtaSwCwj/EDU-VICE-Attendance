import 'package:flutter/material.dart';

/// 페이지 맵 위젯
/// - 10페이지 단위로 행 표시
/// - 등록된 페이지: 초록색
/// - 미등록: 회색
/// - 가로 스크롤 가능
class PageMapWidget extends StatelessWidget {
  final int totalPages;
  final List<int> registeredPages;

  const PageMapWidget({
    super.key,
    required this.totalPages,
    required this.registeredPages,
  });

  @override
  Widget build(BuildContext context) {
    final registeredSet = Set<int>.from(registeredPages);
    final rows = (totalPages / 10).ceil();

    return SizedBox(
      height: rows * 40.0 + 16, // 각 행 40픽셀 + 패딩
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rows, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(10, (colIndex) {
                  final pageNumber = rowIndex * 10 + colIndex + 1;
                  if (pageNumber > totalPages) {
                    return const SizedBox(width: 36); // 빈 공간
                  }

                  final isRegistered = registeredSet.contains(pageNumber);
                  return _buildPageBox(
                    pageNumber: pageNumber,
                    isRegistered: isRegistered,
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPageBox({
    required int pageNumber,
    required bool isRegistered,
  }) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: isRegistered ? Colors.green : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isRegistered ? Colors.green[700]! : Colors.grey[400]!,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          '$pageNumber',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isRegistered ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
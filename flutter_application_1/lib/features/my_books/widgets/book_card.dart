import 'dart:io';
import 'package:flutter/material.dart';
import '../models/local_book.dart';

/// 책 카드 위젯
/// - 표지 이미지 (또는 기본 아이콘)
/// - 제목, 출판사
/// - 진행률 바
class BookCard extends StatelessWidget {
  final LocalBook book;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (book.progress * 100).toInt();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 표지 이미지
            Expanded(
              flex: 3,
              child: book.coverImagePath != null
                  ? Image.file(
                      File(book.coverImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultCover(context),
                    )
                  : _buildDefaultCover(context),
            ),

            // 책 정보
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      book.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 출판사
                    Text(
                      book.publisher,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // 진행률
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: book.progress,
                            backgroundColor: Colors.grey[300],
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$progressPercent%',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover(BuildContext context) {
    final theme = Theme.of(context);
    final subjectIcon = _getSubjectIcon();

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            subjectIcon,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            book.subject,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSubjectIcon() {
    switch (book.subject.toUpperCase()) {
      case 'ENGLISH':
        return Icons.abc;
      case 'MATH':
        return Icons.calculate;
      case 'KOREAN':
        return Icons.translate;
      case 'SCIENCE':
        return Icons.science;
      default:
        return Icons.menu_book;
    }
  }
}
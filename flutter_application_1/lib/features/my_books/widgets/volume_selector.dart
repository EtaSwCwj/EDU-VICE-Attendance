import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import '../models/book_volume.dart';

/// Volume 선택 위젯
/// - LocalBook의 volumes 목록을 표시
/// - 선택된 Volume은 하이라이트 표시
/// - 세션 동안 선택 상태 유지
class VolumeSelector extends StatefulWidget {
  final List<BookVolume> volumes;
  final int initialIndex;
  final ValueChanged<int>? onVolumeChanged;

  const VolumeSelector({
    super.key,
    required this.volumes,
    this.initialIndex = 0,
    this.onVolumeChanged,
  });

  @override
  State<VolumeSelector> createState() => _VolumeSelectorState();
}

class _VolumeSelectorState extends State<VolumeSelector> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onVolumeSelected(int index) {
    if (_selectedIndex == index) return;

    final previousIndex = _selectedIndex;
    setState(() {
      _selectedIndex = index;
    });

    final volumeName = widget.volumes[index].name;
    safePrint(
        '[VolumeSelector] Volume 선택 변경: $previousIndex -> $index ($volumeName)');

    widget.onVolumeChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.volumes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Volume이 1개만 있으면 선택 UI를 표시하지 않음
    if (widget.volumes.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          widget.volumes[0].name,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: widget.volumes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final volume = widget.volumes[index];
          final isSelected = index == _selectedIndex;

          return FilterChip(
            selected: isSelected,
            label: _buildVolumeLabel(volume, theme),
            onSelected: (selected) {
              if (selected) {
                _onVolumeSelected(index);
              }
            },
            showCheckmark: true,
            selectedColor: theme.colorScheme.primaryContainer,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          );
        },
      ),
    );
  }

  Widget _buildVolumeLabel(BookVolume volume, ThemeData theme) {
    final hasPageRange =
        volume.answerStartPage != null && volume.answerEndPage != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          volume.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (hasPageRange) ...[
          const SizedBox(height: 2),
          Text(
            'p.${volume.answerStartPage}-${volume.answerEndPage}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ] else if (volume.totalPages != null) ...[
          const SizedBox(height: 2),
          Text(
            '총 ${volume.totalPages}쪽',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

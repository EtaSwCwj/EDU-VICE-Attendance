import 'package:flutter/material.dart';
import '../models/local_book.dart';
import '../models/book_volume.dart';
import '../models/page_status.dart';

/// 페이지 맵 위젯 v2
/// - Volume별 탭으로 분리
/// - 상태별 색상: 회색(미등록), 파란(정답만), 녹색(문제등록), 연두(완료)
class PageMapWidget extends StatefulWidget {
  final LocalBook book;
  final Function(BookVolume volume, int page)? onPageTap;

  const PageMapWidget({
    super.key,
    required this.book,
    this.onPageTap,
  });

  @override
  State<PageMapWidget> createState() => _PageMapWidgetState();
}

class _PageMapWidgetState extends State<PageMapWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.book.volumes.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final volumes = widget.book.volumes;
    
    // Volume이 1개면 탭 없이 바로 표시
    if (volumes.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegend(),
          const SizedBox(height: 8),
          _buildVolumePageMap(volumes.first),
        ],
      );
    }

    // Volume이 여러 개면 탭으로 표시
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(),
        const SizedBox(height: 8),
        
        // Volume 탭
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: volumes.length > 3,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            tabs: volumes.map((vol) {
              final pageCount = vol.effectiveTotalPages;
              return Tab(
                child: Text(
                  '${vol.name} (${pageCount}p)',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        
        // 페이지 맵
        SizedBox(
          height: 220,
          child: TabBarView(
            controller: _tabController,
            children: volumes.map((vol) => _buildVolumePageMap(vol)).toList(),
          ),
        ),
      ],
    );
  }

  /// 범례 위젯
  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _buildLegendItem(PageStatus.notRegistered, '미촬영'),
        _buildLegendItem(PageStatus.captured, '촬영완료'),
      ],
    );
  }

  Widget _buildLegendItem(PageStatus status, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color(status.colorValue),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  /// Volume별 페이지 맵
  Widget _buildVolumePageMap(BookVolume volume) {
    final pageCount = volume.effectiveTotalPages;
    
    if (pageCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[300], size: 32),
            const SizedBox(height: 8),
            Text(
              '페이지 범위가 설정되지 않았습니다',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '책 수정에서 페이지 범위를 입력하세요',
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
      );
    }

    final startPage = volume.effectiveStartPage;
    final statuses = widget.book.getVolumePageStatuses(volume);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 너비에 맞춰 한 줄에 들어갈 페이지 수 계산
        const double boxSize = 32;
        const double spacing = 4;
        final int pagesPerRow = ((constraints.maxWidth + spacing) / (boxSize + spacing)).floor().clamp(5, 10);
        final rows = (pageCount / pagesPerRow).ceil();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(rows, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Wrap(
                  spacing: spacing,
                  children: List.generate(pagesPerRow, (colIndex) {
                    final pageIndex = rowIndex * pagesPerRow + colIndex;
                    if (pageIndex >= pageCount) {
                      return const SizedBox.shrink();
                    }
                    final pageNumber = startPage + pageIndex;
                    final status = statuses[pageNumber] ?? PageStatus.notRegistered;
                    return _buildPageBox(
                      volume: volume,
                      pageNumber: pageNumber,
                      status: status,
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildPageBox({
    required BookVolume volume,
    required int pageNumber,
    required PageStatus status,
  }) {
    final color = Color(status.colorValue);
    final isLight = status == PageStatus.notRegistered;

    return GestureDetector(
      onTap: () => widget.onPageTap?.call(volume, pageNumber),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isLight ? Colors.grey[400]! : color.withOpacity(0.7),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            '$pageNumber',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isLight ? Colors.grey[700] : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

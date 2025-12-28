import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import '../data/local_book_repository.dart';
import '../models/local_book.dart';
import '../models/book_volume.dart';
import '../widgets/page_map_widget.dart';
import 'image_viewer_page.dart';

/// 책 상세 페이지
class BookDetailPage extends StatefulWidget {
  final String bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final _repository = LocalBookRepository();
  LocalBook? _book;
  bool _isLoading = true;
  bool _showRegisteredPages = false;
  bool _showCaptureRecords = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    safePrint('[BookDetail] 진입: ${widget.bookId}');
    try {
      final book = await _repository.getBook(widget.bookId);
      if (book != null) {
        setState(() {
          _book = book;
          _isLoading = false;
        });
        safePrint('[BookDetail] 책 로드 성공: ${book.title}, 촬영기록: ${book.captureRecords.length}건');
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책을 찾을 수 없습니다')));
          context.pop();
        }
      }
    } catch (e) {
      safePrint('[BookDetail] ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _hasUnsetVolumes() {
    if (_book == null) return false;
    return _book!.volumes.any((vol) => vol.effectiveTotalPages == 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_book?.title ?? '책 상세'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_book != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await context.push<bool>('/my-books/${widget.bookId}/edit');
                  if (result == true) _loadBook();
                } else if (value == 'delete') {
                  final confirmed = await _showDeleteDialog();
                  if (confirmed == true) await _deleteBook();
                } else if (value == 'clear_pages') {
                  final confirmed = await _showClearPagesDialog();
                  if (confirmed == true) await _clearRegisteredPages();
                } else if (value == 'clear_captures') {
                  final confirmed = await _showClearCapturesDialog();
                  if (confirmed == true) await _clearCaptureRecords();
                } else if (value == 'debug') {
                  _showDebugDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('책 정보 수정')])),
                const PopupMenuItem(value: 'debug', child: Row(children: [Icon(Icons.bug_report, color: Colors.purple), SizedBox(width: 8), Text('디버그 정보')])),
                const PopupMenuItem(value: 'clear_pages', child: Row(children: [Icon(Icons.clear_all, color: Colors.orange), SizedBox(width: 8), Text('등록 페이지 초기화')])),
                const PopupMenuItem(value: 'clear_captures', child: Row(children: [Icon(Icons.delete_sweep, color: Colors.orange), SizedBox(width: 8), Text('촬영 기록 초기화')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('삭제', style: TextStyle(color: Colors.red))])),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _book == null
              ? const Center(child: Text('책 정보를 불러올 수 없습니다'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBookInfo(),
                      if (_hasUnsetVolumes()) _buildUnsetWarning(),
                      const Divider(height: 32),
                      _buildPageMapSection(),
                      const SizedBox(height: 16),
                      _buildRegisteredPagesSection(),
                      const SizedBox(height: 16),
                      _buildCaptureRecordsSection(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUnsetWarning() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('페이지 범위 미설정!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            ..._book!.volumes.map((vol) {
              final total = vol.effectiveTotalPages;
              return Text(
                '${vol.name}: ${total > 0 ? "${vol.pageRangeString} ✅" : "❌ 미설정"}',
                style: TextStyle(fontSize: 12, color: total > 0 ? Colors.green : Colors.red),
              );
            }),
            const SizedBox(height: 8),
            Text('책 수정에서 페이지 범위를 설정해주세요.', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildBookInfo() {
    final book = _book!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100, height: 140,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[300]),
            child: book.coverImagePath != null
                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(book.coverImagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildDefaultCover()))
                : _buildDefaultCover(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(book.publisher, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Row(children: [_buildInfoChip(_getSubjectIcon(book.subject), book.subject)]),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.progressSummary, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: book.progress, minHeight: 8, backgroundColor: Colors.grey[300]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      child: Center(child: Icon(_getSubjectIcon(_book!.subject), size: 40, color: Colors.grey[600])),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 12))]),
    );
  }

  Widget _buildPageMapSection() {
    final book = _book!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('페이지 맵', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: PageMapWidget(book: book),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredPagesSection() {
    final book = _book!;
    final pages = List<int>.from(book.registeredPages)..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showRegisteredPages = !_showRegisteredPages),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(_showRegisteredPages ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 20),
                  const SizedBox(width: 4),
                  Text('등록된 정답지 페이지 (${pages.length}개)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          if (_showRegisteredPages)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: pages.isEmpty
                  ? Text('등록된 페이지가 없습니다', style: TextStyle(color: Colors.grey[600]))
                  : Wrap(
                      spacing: 8, runSpacing: 8,
                      children: pages.map((page) {
                        final isOverflow = page > book.totalPages;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOverflow ? Colors.red[100] : Colors.teal[100],
                            borderRadius: BorderRadius.circular(4),
                            border: isOverflow ? Border.all(color: Colors.red) : null,
                          ),
                          child: Text('p.$page', style: TextStyle(fontSize: 12, color: isOverflow ? Colors.red[800] : Colors.teal[800], fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildCaptureRecordsSection() {
    final book = _book!;
    final records = book.captureRecords;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showCaptureRecords = !_showCaptureRecords),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(_showCaptureRecords ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 20),
                  const SizedBox(width: 4),
                  const Icon(Icons.camera_alt, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('문제 촬영 기록 (${records.length}건)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('총 ${book.totalCapturedPages}페이지', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          if (_showCaptureRecords)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withOpacity(0.2))),
              child: records.isEmpty
                  ? Column(
                      children: [
                        Icon(Icons.photo_camera_back, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('아직 촬영 기록이 없습니다', style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 4),
                        Text('"문제 촬영" 버튼으로 문제를 촬영해보세요', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    )
                  : Column(
                      children: [
                        ...records.reversed.take(5).map((record) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.withOpacity(0.2))),
                          child: Row(
                            children: [
                              if (record.imagePath != null && record.imagePath!.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ImageViewerPage(imagePath: record.imagePath!)));
                                  },
                                  child: Container(
                                    width: 60, height: 60,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.withOpacity(0.3))),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.file(File(record.imagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[100], child: Icon(Icons.broken_image, color: Colors.grey[400], size: 24))),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                                          child: Text('${record.pages.join(", ")}p', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(record.volumeName, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_formatDateTime(record.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                        if (records.length > 5)
                          Padding(padding: const EdgeInsets.only(top: 4), child: Text('... 외 ${records.length - 5}건 더 있음', style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await context.push<bool>('/my-books/${widget.bookId}/answer-camera');
                if (result == true) _loadBook();
              },
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('정답지 등록'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await context.push<bool>('/my-books/${widget.bookId}/problem-camera');
                if (result == true) _loadBook();
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('문제 촬영'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('책 삭제'),
        content: Text('정말로 "${_book?.title}"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<bool?> _showClearPagesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('등록 페이지 초기화'),
        content: const Text('등록된 모든 정답지 페이지를 초기화하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('초기화', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
  }

  Future<bool?> _showClearCapturesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('촬영 기록 초기화'),
        content: const Text('모든 문제 촬영 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('초기화', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
  }

  Future<void> _clearRegisteredPages() async {
    try {
      await _repository.clearRegisteredPages(widget.bookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('등록 페이지가 초기화되었습니다')));
        _loadBook();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('초기화 실패: $e')));
    }
  }

  Future<void> _clearCaptureRecords() async {
    try {
      await _repository.clearCaptureRecords(widget.bookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('촬영 기록이 초기화되었습니다')));
        _loadBook();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('초기화 실패: $e')));
    }
  }

  Future<void> _deleteBook() async {
    try {
      await _repository.deleteBook(widget.bookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책이 삭제되었습니다')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  String _formatDateTime(DateTime time) {
    final now = DateTime.now();
    final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return isToday ? '오늘 $timeStr' : '${time.month}/${time.day} $timeStr';
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toUpperCase()) {
      case 'ENGLISH': return Icons.abc;
      case 'MATH': return Icons.calculate;
      case 'KOREAN': return Icons.translate;
      case 'SCIENCE': return Icons.science;
      default: return Icons.menu_book;
    }
  }

  void _showDebugDialog() {
    if (_book == null) return;
    final book = _book!;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.bug_report, color: Colors.purple), SizedBox(width: 8), Text('디버그 정보')]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _debugSection('기본 정보', ['ID: ${book.id}', '제목: ${book.title}', '출판사: ${book.publisher}', '과목: ${book.subject}']),
              const Divider(),
              _debugSection('페이지 통계', ['totalPages: ${book.totalPages}', 'capturedPages: ${book.totalCapturedPages}', 'answerPages: ${book.totalAnswerPages}', 'progress: ${(book.progress * 100).toStringAsFixed(1)}%']),
              const Divider(),
              _debugSection('Volumes (${book.volumes.length}개)', book.volumes.map((v) => '[${v.index}] ${v.name}: ${v.pageRangeString} (${v.effectiveTotalPages}p)').toList()),
              const Divider(),
              _debugSection('촬영 기록', ['${book.captureRecords.length}건']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (ctx2) => AlertDialog(
                  title: const Text('Volume 초기화'),
                  content: const Text('모든 Volume의 페이지 범위를 초기화합니까?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx2, false), child: const Text('취소')),
                    TextButton(onPressed: () => Navigator.pop(ctx2, true), child: const Text('초기화', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                final resetVolumes = book.volumes.map((v) => BookVolume(index: v.index, name: v.name)).toList();
                final resetBook = book.copyWith(volumes: resetVolumes);
                await _repository.updateBook(resetBook);
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadBook();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Volume 초기화 완료')));
                }
              }
            },
            child: const Text('Volume 초기화', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              safePrint('===== DB DUMP =====');
              safePrint(book.toJson().toString());
              safePrint('===== END =====');
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('로그 출력됨')));
            },
            child: const Text('로그'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
        ],
      ),
    );
  }

  Widget _debugSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(padding: const EdgeInsets.only(left: 8, bottom: 2), child: Text(item, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')))),
      ],
    );
  }
}

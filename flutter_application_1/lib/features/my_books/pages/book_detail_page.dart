import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../data/local_book_repository.dart';
import '../data/problem_repository.dart';
import '../models/local_book.dart';
import '../models/book_volume.dart';
import '../models/problem.dart';
import '../models/toc_entry.dart';
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
  final _problemRepository = ProblemRepository();
  LocalBook? _book;
  List<Problem> _problems = [];
  bool _isLoading = true;
  bool _showRegisteredPages = false;
  bool _showCaptureRecords = true;
  bool _showTableOfContents = false;

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
        // 분할된 문제도 로드
        final problems = await _problemRepository.getProblemsForBook(widget.bookId);
        setState(() {
          _book = book;
          _problems = problems;
          _isLoading = false;
        });
        safePrint('[BookDetail] 책 로드 성공: ${book.title}, 촬영기록: ${book.captureRecords.length}건, 분할문제: ${problems.length}개');
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

  /// 특정 페이지의 분할된 문제들
  List<Problem> _getProblemsForPage(int page) {
    return _problems.where((p) => p.page == page).toList()
      ..sort((a, b) => a.problemNumber.compareTo(b.problemNumber));
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
                      _buildTableOfContentsSection(),
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
          const SizedBox(height: 4),
          Text('문제 촬영 여부를 표시합니다', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
    final answerContents = book.answerContents;

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
                  const Icon(Icons.fact_check, size: 16, color: Colors.teal),
                  const SizedBox(width: 4),
                  Text('등록된 정답지 페이지 (${pages.length}개)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  if (answerContents.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                      child: Text('${answerContents.length}개 내용 있음', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_showRegisteredPages)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.teal.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.withOpacity(0.3))),
              child: pages.isEmpty
                  ? Column(
                      children: [
                        Icon(Icons.description_outlined, size: 32, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('등록된 정답지가 없습니다', style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 4),
                        Text('"정답지 등록" 버튼으로 정답지를 촬영하세요', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('탭하여 정답 내용 확인', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: pages.map((page) {
                            final hasContent = answerContents.containsKey(page);
                            return GestureDetector(
                              onTap: () => _showAnswerContentDialog(page, answerContents[page]),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasContent ? Colors.teal[100] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: hasContent ? Colors.teal : Colors.grey[400]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('p.$page', style: TextStyle(fontSize: 12, color: hasContent ? Colors.teal[800] : Colors.grey[600], fontWeight: FontWeight.w500)),
                                    if (hasContent) ...[
                                      const SizedBox(width: 4),
                                      Icon(Icons.visibility, size: 12, color: Colors.teal[600]),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableOfContentsSection() {
    final book = _book!;
    final tocEntries = book.tableOfContents;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showTableOfContents = !_showTableOfContents),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(_showTableOfContents ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 20),
                  const SizedBox(width: 4),
                  const Icon(Icons.list_alt, size: 16, color: Colors.teal),
                  const SizedBox(width: 4),
                  Text('목차 (${tocEntries.length}개)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          if (_showTableOfContents)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: tocEntries.isEmpty
                  ? Column(
                      children: [
                        Icon(Icons.toc, size: 32, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('등록된 목차가 없습니다', style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openTocCamera(),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('목차 페이지 촬영'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...tocEntries.map((entry) => InkWell(
                          onTap: () => _editTocEntry(entry),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.unitName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  entry.endPage != null
                                      ? 'p.${entry.startPage} - p.${entry.endPage}'
                                      : 'p.${entry.startPage}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openTocCamera(),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('목차 페이지 촬영'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _resetTableOfContents(),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('목차 초기화'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  /// 정답 내용 확인 다이얼로그
  void _showAnswerContentDialog(int page, String? content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(4)),
              child: Text('Page $page', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: content != null && content.isNotEmpty
              ? SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      content,
                      style: const TextStyle(fontSize: 13, height: 1.6, fontFamily: 'monospace'),
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber, size: 48, color: Colors.orange[300]),
                      const SizedBox(height: 16),
                      Text('정답 내용이 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('페이지 번호만 등록되었습니다', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ],
                  ),
                ),
        ),
        actions: [
          if (content != null && content.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                // 클립보드 복사
                // Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('복사 기능은 추후 추가 예정')));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('복사'),
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
                  if (_problems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(10)),
                      child: Text('${_problems.length}문제 분할됨', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
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
                        ...records.reversed.take(10).map((record) => _buildCaptureRecordItem(record)),
                        if (records.length > 10)
                          Padding(padding: const EdgeInsets.only(top: 4), child: Text('... 외 ${records.length - 10}건 더 있음', style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  /// 촬영 기록 아이템 (분할된 문제 표시 포함)
  Widget _buildCaptureRecordItem(CaptureRecord record) {
    // 이 촬영 기록에 해당하는 분할 문제들
    final problemsForRecord = <Problem>[];
    for (final page in record.pages) {
      problemsForRecord.addAll(_getProblemsForPage(page));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 페이지 정보 + 원본 이미지
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // 원본 이미지 썸네일
                if (record.imagePath != null && record.imagePath!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ImageViewerPage(imagePath: record.imagePath!)));
                    },
                    child: Container(
                      width: 50, height: 50,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.withOpacity(0.3))),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(File(record.imagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[100], child: Icon(Icons.broken_image, color: Colors.grey[400], size: 20))),
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
                          Text(record.volumeName, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(_formatDateTime(record.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                          if (problemsForRecord.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text('${problemsForRecord.length}문제 분할', style: TextStyle(fontSize: 10, color: Colors.purple[700], fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 분할된 문제들 (있으면)
          if (problemsForRecord.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text('분할된 문제', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: problemsForRecord.map((problem) => _buildProblemChip(problem)).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 분할된 문제 칩 (클릭하면 이미지 보기)
  Widget _buildProblemChip(Problem problem) {
    final hasImage = problem.imagePath.isNotEmpty && File(problem.imagePath).existsSync();
    
    return GestureDetector(
      onTap: hasImage 
          ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => ImageViewerPage(imagePath: problem.imagePath)))
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: hasImage ? Colors.purple[50] : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: hasImage ? Colors.purple.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${problem.page}p-${problem.problemNumber}번', style: TextStyle(fontSize: 11, color: hasImage ? Colors.purple[700] : Colors.grey[600], fontWeight: FontWeight.w500)),
            if (hasImage) ...[
              const SizedBox(width: 4),
              Icon(Icons.image, size: 12, color: Colors.purple[400]),
            ],
          ],
        ),
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
      // 1. 촬영 기록 삭제
      await _repository.clearCaptureRecords(widget.bookId);
      
      // 2. 분할된 문제 DB 삭제
      await _problemRepository.deleteProblemsForBook(widget.bookId);
      safePrint('[BookDetail] 분할된 문제 DB 삭제 완료');
      
      // 3. 이미지 파일 삭제 (captures/{bookId}/ 폴더)
      final documentsDir = await getApplicationDocumentsDirectory();
      final capturesDir = Directory('${documentsDir.path}/captures/${widget.bookId}');
      if (await capturesDir.exists()) {
        await capturesDir.delete(recursive: true);
        safePrint('[BookDetail] 이미지 폴더 삭제 완료: ${capturesDir.path}');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('촬영 기록, 문제, 이미지가 모두 초기화되었습니다')));
        _loadBook();
      }
    } catch (e) {
      safePrint('[BookDetail] 초기화 실패: $e');
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
              _debugSection('분할된 문제', ['${_problems.length}개']),
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
              safePrint('===== PROBLEMS =====');
              for (final p in _problems) {
                safePrint('${p.page}p-${p.problemNumber}: ${p.imagePath}');
              }
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

  /// 목차 촬영 페이지 열기
  Future<void> _openTocCamera() async {
    final result = await context.push<bool>('/toc-camera/${widget.bookId}');
    if (result == true) {
      _loadBook();
    }
  }

  /// 목차 항목 편집 (추후 구현 가능)
  void _editTocEntry(TocEntry entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('목차 편집 기능은 추후 지원 예정입니다')),
    );
  }

  /// 목차 초기화
  Future<void> _resetTableOfContents() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목차 초기화'),
        content: const Text('등록된 목차를 모두 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('초기화', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedBook = _book!.copyWith(tableOfContents: []);
      await _repository.updateBook(updatedBook);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목차가 초기화되었습니다')),
        );
        _loadBook();
      }
    }
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

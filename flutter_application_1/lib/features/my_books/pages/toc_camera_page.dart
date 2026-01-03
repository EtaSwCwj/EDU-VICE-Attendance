import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:go_router/go_router.dart';
import '../models/local_book.dart';
import '../models/toc_entry.dart';
import '../data/local_book_repository.dart';
import '../../../shared/services/claude_api_service.dart';

/// 목차 촬영 페이지
/// - 한 장씩만 촬영 (1페이지 = 1사진)
/// - 촬영 후 AI 인식
/// - 인식 결과 수정/삭제/추가 가능
class TocCameraPage extends StatefulWidget {
  final String bookId;

  const TocCameraPage({super.key, required this.bookId});

  @override
  State<TocCameraPage> createState() => _TocCameraPageState();
}

class _TocCameraPageState extends State<TocCameraPage> {
  final _bookRepository = LocalBookRepository();
  final _claudeService = ClaudeApiService();

  LocalBook? _book;
  List<TocEntry> _tocEntries = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String _processingStatus = '';

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final book = await _bookRepository.getBook(widget.bookId);
      if (mounted) {
        setState(() {
          _book = book;
          _tocEntries = List.from(book?.tableOfContents ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      safePrint('[TocCamera] 책 로딩 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startScanning() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures();
      if (pictures == null || pictures.isEmpty) return;

      setState(() {
        _isProcessing = true;
        _processingStatus = '목차 인식 중...';
      });

      // 각 사진에 대해 목차 인식
      for (final picturePath in pictures) {
        await _processImage(picturePath);
      }

      setState(() {
        _isProcessing = false;
        _processingStatus = '';
      });
    } catch (e) {
      safePrint('[TocCamera] 스캔 오류: $e');
      setState(() {
        _isProcessing = false;
        _processingStatus = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('촬영 오류: $e')),
        );
      }
    }
  }

  Future<void> _processImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);

      setState(() => _processingStatus = '목차 분석 중...');

      // Claude API로 목차 인식
      debugPrint('[TocCamera] API 호출 시작');
      final extractedEntries = await _claudeService.extractTableOfContents(imageFile);
      debugPrint('[TocCamera] API 응답: ${extractedEntries.length}개 항목');

      for (final entry in extractedEntries) {
        debugPrint('[TocCamera] entry: $entry');
      }

      setState(() {
        // 인식된 항목들을 리스트에 추가
        for (final entry in extractedEntries) {
          // 안전한 타입 변환
          final unitName = entry['unitName']?.toString() ?? '';
          final startPageRaw = entry['startPage'];
          final startPage = startPageRaw is int
              ? startPageRaw
              : int.tryParse(startPageRaw?.toString() ?? '') ?? 0;
          final endPageRaw = entry['endPage'];
          final endPage = endPageRaw == null
              ? null
              : (endPageRaw is int ? endPageRaw : int.tryParse(endPageRaw.toString()));

          debugPrint('[TocCamera] 추가: $unitName, p.$startPage');

          if (unitName.isNotEmpty && startPage > 0) {
            _tocEntries.add(TocEntry(
              unitName: unitName,
              startPage: startPage,
              endPage: endPage,
            ));
          }
        }
      });

      debugPrint('[TocCamera] 최종 항목 수: ${_tocEntries.length}');

      // 임시 파일 삭제
      try {
        await imageFile.delete();
      } catch (e) {
        safePrint('[TocCamera] 임시 파일 삭제 실패: $e');
      }
    } catch (e) {
      safePrint('[TocCamera] 이미지 처리 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('목차 인식 오류: $e')),
        );
      }
    }
  }

  Future<void> _saveToc() async {
    if (_book == null) return;

    setState(() => _isProcessing = true);

    try {
      // 책 정보 업데이트
      final updatedBook = _book!.copyWith(
        tableOfContents: _tocEntries,
        updatedAt: DateTime.now(),
      );

      await _bookRepository.updateBook(updatedBook);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목차가 저장되었습니다')),
        );
        context.pop(true); // 성공 표시로 pop
      }
    } catch (e) {
      safePrint('[TocCamera] 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 오류: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showEditDialog(TocEntry? entry, int? index) {
    final isNew = entry == null;
    final unitNameController = TextEditingController(text: entry?.unitName ?? '');
    final startPageController = TextEditingController(
      text: entry?.startPage.toString() ?? '',
    );
    final endPageController = TextEditingController(
      text: entry?.endPage?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNew ? '목차 항목 추가' : '목차 항목 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: unitNameController,
              decoration: const InputDecoration(
                labelText: '단원명',
                hintText: 'Unit 01 문장을 이루는 요소',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: startPageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '시작 페이지',
                hintText: '8',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: endPageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '끝 페이지 (선택)',
                hintText: '10',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final unitName = unitNameController.text.trim();
              final startPageStr = startPageController.text.trim();

              if (unitName.isEmpty || startPageStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('단원명과 시작 페이지는 필수입니다')),
                );
                return;
              }

              final startPage = int.tryParse(startPageStr);
              if (startPage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('올바른 페이지 번호를 입력하세요')),
                );
                return;
              }

              final endPageStr = endPageController.text.trim();
              final endPage = endPageStr.isEmpty ? null : int.tryParse(endPageStr);

              final newEntry = TocEntry(
                unitName: unitName,
                startPage: startPage,
                endPage: endPage,
              );

              setState(() {
                if (isNew) {
                  _tocEntries.add(newEntry);
                } else {
                  _tocEntries[index!] = newEntry;
                }
              });

              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _deleteEntry(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('항목 삭제'),
        content: Text('"${_tocEntries[index].unitName}" 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _tocEntries.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('목차 촬영'),
        actions: [
          TextButton(
            onPressed: _tocEntries.isEmpty ? null : _saveToc,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단: 목차 항목 리스트
          Expanded(
            child: _tocEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.toc,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '목차 페이지를 촬영해주세요',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tocEntries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _tocEntries.length) {
                        // 마지막: 항목 추가 버튼
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: OutlinedButton.icon(
                            onPressed: () => _showEditDialog(null, null),
                            icon: const Icon(Icons.add),
                            label: const Text('항목 추가'),
                          ),
                        );
                      }

                      final entry = _tocEntries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(entry.unitName),
                          subtitle: Text(
                            entry.endPage != null
                                ? 'p.${entry.startPage} - p.${entry.endPage}'
                                : 'p.${entry.startPage}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(entry, index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteEntry(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 하단: 촬영 버튼
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _startScanning,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_isProcessing ? _processingStatus : '목차 페이지 촬영'),
                  ),
                ),
                if (_tocEntries.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _isProcessing ? null : _saveToc,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('촬영 완료'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
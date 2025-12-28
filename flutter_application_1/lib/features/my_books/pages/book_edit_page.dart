import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/local_book.dart';
import '../models/book_volume.dart';
import '../data/local_book_repository.dart';

class BookEditPage extends StatefulWidget {
  final String bookId;

  const BookEditPage({
    Key? key,
    required this.bookId,
  }) : super(key: key);

  @override
  State<BookEditPage> createState() => _BookEditPageState();
}

class _BookEditPageState extends State<BookEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _publisherController = TextEditingController();
  final _localBookRepository = LocalBookRepository();

  // 분권별 페이지 범위 컨트롤러들
  List<TextEditingController> _startPageControllers = [];
  List<TextEditingController> _endPageControllers = [];

  LocalBook? _book;
  String _selectedSubject = 'MATH';
  bool _isLoading = true;
  bool _isSaving = false;

  // 과목 옵션들
  final Map<String, String> _subjectOptions = {
    'MATH': '수학',
    'ENGLISH': '영어',
    'KOREAN': '국어',
    'SCIENCE': '과학',
  };

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _publisherController.dispose();

    // 분권별 페이지 범위 컨트롤러들 해제
    for (var controller in _startPageControllers) {
      controller.dispose();
    }
    for (var controller in _endPageControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadBook() async {
    try {
      safePrint('[BookEditPage] 책 정보 로드 중: ${widget.bookId}');
      final book = await _localBookRepository.getBook(widget.bookId);

      if (book == null) {
        safePrint('[BookEditPage] ERROR: 책을 찾을 수 없음');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('책을 찾을 수 없습니다')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // 분권별 페이지 범위 컨트롤러들 생성
      _initPageControllers(book.volumes);

      setState(() {
        _book = book;
        _titleController.text = book.title;
        _publisherController.text = book.publisher;
        _selectedSubject = book.subject;
        _isLoading = false;
      });

      safePrint('[BookEditPage] 책 정보 로드 완료: ${book.title}');
    } catch (e) {
      safePrint('[BookEditPage] ERROR: 책 정보 로드 실패 - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('책 정보 로드 실패: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  /// 분권별 페이지 범위 컨트롤러들을 초기화
  void _initPageControllers(List<BookVolume> volumes) {
    // 기존 컨트롤러들 해제
    for (var controller in _startPageControllers) {
      controller.dispose();
    }
    for (var controller in _endPageControllers) {
      controller.dispose();
    }

    // 새로운 컨트롤러들 생성
    _startPageControllers = volumes.map((volume) {
      final controller = TextEditingController();
      if (volume.answerStartPage != null) {
        controller.text = volume.answerStartPage.toString();
      }
      return controller;
    }).toList();

    _endPageControllers = volumes.map((volume) {
      final controller = TextEditingController();
      if (volume.totalPages != null && volume.answerStartPage != null) {
        // totalPages가 있으면 endPage = startPage + totalPages - 1
        final endPage = volume.answerStartPage! + volume.totalPages! - 1;
        controller.text = endPage.toString();
      } else if (volume.answerEndPage != null) {
        controller.text = volume.answerEndPage.toString();
      }
      return controller;
    }).toList();

    safePrint('[BookEditPage] 페이지 범위 컨트롤러 생성 완료: ${volumes.length}개');
  }

  /// 페이지 수 표시 위젯 생성
  Widget _buildPageCountDisplay(int volumeIndex) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _startPageControllers[volumeIndex],
        _endPageControllers[volumeIndex],
      ]),
      builder: (context, child) {
        final startText = _startPageControllers[volumeIndex].text.trim();
        final endText = _endPageControllers[volumeIndex].text.trim();

        if (startText.isEmpty || endText.isEmpty) {
          return const SizedBox();
        }

        final startPage = int.tryParse(startText);
        final endPage = int.tryParse(endText);

        if (startPage == null || endPage == null || startPage > endPage) {
          return const Text(
            '페이지 범위를 확인해주세요',
            style: TextStyle(color: Colors.red, fontSize: 12),
          );
        }

        final totalPages = endPage - startPage + 1;
        return Text(
          '총 $totalPages 페이지',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate() || _book == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      safePrint('[BookEditPage] 책 정보 저장 중...');

      // 분권별 페이지 범위 정보 업데이트
      final updatedVolumes = <BookVolume>[];
      for (int i = 0; i < _book!.volumes.length; i++) {
        final volume = _book!.volumes[i];

        int? startPage;
        int? endPage;
        int? totalPages;

        // 시작 페이지 파싱
        if (_startPageControllers[i].text.isNotEmpty) {
          startPage = int.tryParse(_startPageControllers[i].text.trim());
        }

        // 끝 페이지 파싱
        if (_endPageControllers[i].text.isNotEmpty) {
          endPage = int.tryParse(_endPageControllers[i].text.trim());
        }

        // totalPages 계산 (endPage - startPage + 1)
        if (startPage != null && endPage != null && endPage >= startPage) {
          totalPages = endPage - startPage + 1;
        }

        updatedVolumes.add(BookVolume(
          index: volume.index,
          name: volume.name,
          answerStartPage: startPage,
          answerEndPage: endPage,
          totalPages: totalPages,
        ));

        safePrint('[BookEditPage] Volume ${i+1} 업데이트: startPage=$startPage, endPage=$endPage, totalPages=$totalPages');
      }

      final updatedBook = _book!.copyWith(
        title: _titleController.text.trim(),
        publisher: _publisherController.text.trim(),
        subject: _selectedSubject,
        volumes: updatedVolumes,
        updatedAt: DateTime.now(),
      );

      await _localBookRepository.updateBook(updatedBook);

      safePrint('[BookEditPage] 책 정보 저장 완료: ${updatedBook.title}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('책 정보가 저장되었습니다')),
        );
        Navigator.of(context).pop(true); // 성공 결과 반환
      }
    } catch (e) {
      safePrint('[BookEditPage] ERROR: 책 정보 저장 실패 - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('책 정보 수정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 기본 정보 섹션
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '기본 정보',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 책 제목
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: '책 제목',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '책 제목을 입력해주세요';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 출판사
                            TextFormField(
                              controller: _publisherController,
                              decoration: const InputDecoration(
                                labelText: '출판사',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '출판사를 입력해주세요';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 과목 선택
                            DropdownButtonFormField<String>(
                              value: _selectedSubject,
                              decoration: const InputDecoration(
                                labelText: '과목',
                                border: OutlineInputBorder(),
                              ),
                              items: _subjectOptions.entries.map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedSubject = value;
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '과목을 선택해주세요';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 분권별 페이지 범위 섹션
                    if (_book != null && _book!.volumes.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📚 분권별 페이지 범위',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              ..._book!.volumes.asMap().entries.map((entry) {
                                final index = entry.key;
                                final volume = entry.value;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (index > 0) const SizedBox(height: 16),

                                    Text(
                                      '${volume.name} (${index + 1}권)',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        // 시작 페이지
                                        Expanded(
                                          child: TextFormField(
                                            controller: _startPageControllers.length > index
                                              ? _startPageControllers[index]
                                              : null,
                                            decoration: const InputDecoration(
                                              labelText: '정답지 시작p',
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                              hintText: '1',
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value != null && value.isNotEmpty) {
                                                final pageNum = int.tryParse(value.trim());
                                                if (pageNum == null || pageNum < 1) {
                                                  return '올바른 페이지 번호를 입력하세요';
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        // 끝 페이지
                                        Expanded(
                                          child: TextFormField(
                                            controller: _endPageControllers.length > index
                                              ? _endPageControllers[index]
                                              : null,
                                            decoration: const InputDecoration(
                                              labelText: '정답지 끝p',
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                              hintText: '19',
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value != null && value.isNotEmpty) {
                                                final pageNum = int.tryParse(value.trim());
                                                if (pageNum == null || pageNum < 1) {
                                                  return '올바른 페이지 번호를 입력하세요';
                                                }

                                                // 시작 페이지보다 큰지 확인
                                                if (_startPageControllers.length > index) {
                                                  final startText = _startPageControllers[index].text.trim();
                                                  if (startText.isNotEmpty) {
                                                    final startPage = int.tryParse(startText);
                                                    if (startPage != null && pageNum < startPage) {
                                                      return '끝 페이지는 시작 페이지보다 커야 합니다';
                                                    }
                                                  }
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // 페이지 수 표시
                                    if (_startPageControllers.length > index &&
                                        _endPageControllers.length > index)
                                      _buildPageCountDisplay(index),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],

                    // 저장 버튼
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveBook,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('저장 중...'),
                              ],
                            )
                          : const Text(
                              '저장',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
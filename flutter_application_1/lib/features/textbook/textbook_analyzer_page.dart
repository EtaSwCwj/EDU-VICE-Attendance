import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../shared/services/claude_api_service.dart';
import '../../models/ModelProvider.dart';

class TextbookAnalyzerPage extends StatefulWidget {
  const TextbookAnalyzerPage({super.key});

  @override
  State<TextbookAnalyzerPage> createState() => _TextbookAnalyzerPageState();
}

class _TextbookAnalyzerPageState extends State<TextbookAnalyzerPage> {
  final _claudeService = ClaudeApiService();

  // 파일 관련
  File? _selectedFile;
  String? _fileName;
  bool _isPdf = false;
  
  // 분석 결과
  Map<String, dynamic>? _analysisResult;
  bool _isLoading = false;
  String? _error;
  
  // 교재 선택/생성
  List<Textbook> _existingTextbooks = [];
  Textbook? _selectedTextbook;
  bool _createNewTextbook = true;
  
  // 새 교재 정보 입력
  final _titleController = TextEditingController();
  final _publisherController = TextEditingController();
  final _gradeController = TextEditingController(text: '중2');
  final _semesterController = TextEditingController(text: '1');
  final _publishYearController = TextEditingController(text: '2024');
  Subject _selectedSubject = Subject.MATH;
  
  // 단원 정보
  final _chapterNumberController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _loadExistingTextbooks();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _publisherController.dispose();
    _gradeController.dispose();
    _semesterController.dispose();
    _publishYearController.dispose();
    _chapterNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingTextbooks() async {
    try {
      final request = ModelQueries.list(Textbook.classType);
      final response = await Amplify.API.query(request: request).response;
      
      if (response.data != null) {
        setState(() {
          _existingTextbooks = response.data!.items.whereType<Textbook>().toList();
        });
        safePrint('[TextbookAnalyzer] 기존 교재 로드: ${_existingTextbooks.length}개');
      }
    } catch (e) {
      safePrint('[TextbookAnalyzer] 교재 로드 실패: $e');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final extension = path.split('.').last.toLowerCase();
      
      setState(() {
        _selectedFile = File(path);
        _fileName = result.files.single.name;
        _isPdf = extension == 'pdf';
        _analysisResult = null;
        _error = null;
      });
      
      safePrint('[TextbookAnalyzer] 파일 선택: $_fileName, isPdf: $_isPdf');
    }
  }

  Future<void> _analyzeFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _claudeService.analyzeTextbookFile(_selectedFile!);
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
      
      // 분석 결과에서 제목 자동 채우기
      final pageInfo = result?['pageInfo'] as Map<String, dynamic>?;
      if (pageInfo != null && _titleController.text.isEmpty) {
        _titleController.text = pageInfo['chapterTitle']?.toString() ?? '';
      }
      
      safePrint('[TextbookAnalyzer] 분석 완료');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToDatabase() async {
    if (_analysisResult == null) return;
    
    // 유효성 검사
    if (_createNewTextbook && _titleController.text.isEmpty) {
      _showError('교재 제목을 입력하세요');
      return;
    }
    if (!_createNewTextbook && _selectedTextbook == null) {
      _showError('교재를 선택하세요');
      return;
    }
    if (_chapterNumberController.text.isEmpty) {
      _showError('단원 번호를 입력하세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pageInfo = _analysisResult!['pageInfo'] as Map<String, dynamic>?;
      final problems = _analysisResult!['problems'] as List<dynamic>? ?? [];

      if (pageInfo == null) {
        throw Exception('분석 결과에 pageInfo가 없습니다');
      }

      String textbookId;
      
      // 1. Textbook 생성 또는 선택
      if (_createNewTextbook) {
        final textbook = Textbook(
          title: _titleController.text,
          subject: _selectedSubject,
          grade: _gradeController.text,
          semester: _semesterController.text,
          publisher: _publisherController.text.isNotEmpty 
              ? _publisherController.text 
              : '미정',
          edition: '1',
          publishYear: int.tryParse(_publishYearController.text) ?? 2024,
          totalPages: pageInfo['pageNumber'] as int? ?? 1,
          isVerified: false,
        );

        final textbookRequest = ModelMutations.create(textbook);
        final textbookResponse = await Amplify.API.mutate(request: textbookRequest).response;

        if (textbookResponse.hasErrors) {
          throw Exception('교재 저장 실패: ${textbookResponse.errors}');
        }
        
        textbookId = textbookResponse.data!.id;
        safePrint('[TextbookAnalyzer] 교재 저장 성공: $textbookId');
      } else {
        textbookId = _selectedTextbook!.id;
        safePrint('[TextbookAnalyzer] 기존 교재 사용: $textbookId');
      }

      // 2. TextbookChapter 생성
      final chapterNumber = int.tryParse(_chapterNumberController.text) ?? 1;
      final pageNumber = pageInfo['pageNumber'] as int? ?? 1;
      
      final chapter = TextbookChapter(
        textbookId: textbookId,
        number: chapterNumber,
        title: pageInfo['chapterTitle']?.toString() ?? '단원 $chapterNumber',
        section: pageInfo['section']?.toString(),
        startPage: pageNumber,
        endPage: pageNumber, // 한 페이지만 분석했으므로
      );

      final chapterRequest = ModelMutations.create(chapter);
      final chapterResponse = await Amplify.API.mutate(request: chapterRequest).response;

      if (chapterResponse.hasErrors) {
        throw Exception('단원 저장 실패: ${chapterResponse.errors}');
      }
      
      final chapterId = chapterResponse.data!.id;
      safePrint('[TextbookAnalyzer] 단원 저장 성공: $chapterId');

      // 3. Problem 각각 생성
      int savedCount = 0;
      for (final prob in problems) {
        final probMap = prob as Map<String, dynamic>;
        
        // Difficulty enum 변환
        Difficulty difficulty;
        switch (probMap['difficulty']?.toString().toUpperCase()) {
          case 'BASIC':
            difficulty = Difficulty.BASIC;
            break;
          case 'HARD':
            difficulty = Difficulty.HARD;
            break;
          default:
            difficulty = Difficulty.MEDIUM;
        }
        
        // ProblemCategory enum 변환
        ProblemCategory category;
        switch (probMap['category']?.toString().toUpperCase()) {
          case 'CONCEPT':
            category = ProblemCategory.CONCEPT;
            break;
          default:
            category = ProblemCategory.APPLICATION;
        }
        
        // concepts 리스트 변환
        List<String>? concepts;
        if (probMap['concepts'] != null) {
          concepts = (probMap['concepts'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
        }
        
        final problem = Problem(
          textbookId: textbookId,
          chapterId: chapterId,
          page: pageNumber,
          number: probMap['number']?.toString() ?? '?',
          difficulty: difficulty,
          category: category,
          question: probMap['question']?.toString(),
          answer: probMap['answer']?.toString() ?? '-',
          concepts: concepts,
        );

        final problemRequest = ModelMutations.create(problem);
        final problemResponse = await Amplify.API.mutate(request: problemRequest).response;

        if (!problemResponse.hasErrors) {
          savedCount++;
        } else {
          safePrint('[TextbookAnalyzer] 문제 저장 실패: ${problemResponse.errors}');
        }
      }
      
      safePrint('[TextbookAnalyzer] 문제 저장 완료: $savedCount/${problems.length}개');

      // 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 완료! 단원 1개, 문제 $savedCount개'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 교재 목록 새로고침
        _loadExistingTextbooks();
      }
    } catch (e) {
      safePrint('[TextbookAnalyzer] 저장 실패: $e');
      _showError('저장 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('교재 분석'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings/api-key'),
            tooltip: 'API 키 설정',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === 1. 교재 선택/생성 ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. 교재 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    // 새 교재 / 기존 교재 선택
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('새 교재'),
                          selected: _createNewTextbook,
                          onSelected: (v) => setState(() => _createNewTextbook = true),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('기존 교재'),
                          selected: !_createNewTextbook,
                          onSelected: (v) => setState(() => _createNewTextbook = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_createNewTextbook) ...[
                      // 새 교재 정보 입력
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '교재명 *',
                          hintText: '예: 개념유형 파워 중2-1',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _publisherController,
                              decoration: const InputDecoration(
                                labelText: '출판사',
                                hintText: '비상교육',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<Subject>(
                              value: _selectedSubject,
                              decoration: const InputDecoration(
                                labelText: '과목',
                                border: OutlineInputBorder(),
                              ),
                              items: Subject.values.map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(_subjectName(s)),
                              )).toList(),
                              onChanged: (v) => setState(() => _selectedSubject = v ?? Subject.MATH),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _gradeController,
                              decoration: const InputDecoration(
                                labelText: '학년',
                                hintText: '중2',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _semesterController,
                              decoration: const InputDecoration(
                                labelText: '학기',
                                hintText: '1',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _publishYearController,
                              decoration: const InputDecoration(
                                labelText: '출판년도',
                                hintText: '2024',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // 기존 교재 선택
                      DropdownButtonFormField<Textbook>(
                        value: _selectedTextbook,
                        decoration: const InputDecoration(
                          labelText: '교재 선택',
                          border: OutlineInputBorder(),
                        ),
                        items: _existingTextbooks.map((t) => DropdownMenuItem(
                          value: t,
                          child: Text('${t.title} (${t.grade})'),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedTextbook = v),
                        hint: const Text('교재를 선택하세요'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // === 2. 단원 번호 ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('2. 단원 번호', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _chapterNumberController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('단원', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // === 3. 파일 선택 ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('3. 페이지 이미지', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: _selectedFile != null
                            ? _isPdf
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                                        const SizedBox(height: 8),
                                        Text(_fileName ?? 'PDF', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_selectedFile!, fit: BoxFit.contain),
                                  )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('탭하여 파일 선택', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 분석 버튼
            ElevatedButton.icon(
              onPressed: _selectedFile != null && !_isLoading ? _analyzeFile : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? '분석 중...' : '파일 분석'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            // 에러 표시
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            ],

            // 분석 결과
            if (_analysisResult != null) ...[
              const SizedBox(height: 24),
              
              // 요약 카드
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('분석 결과', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveToDatabase,
                            icon: const Icon(Icons.save),
                            label: const Text('DB 저장'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildResultSummary(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 상세 JSON (접을 수 있게)
              ExpansionTile(
                title: const Text('상세 JSON 보기'),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(_analysisResult),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultSummary() {
    final pageInfo = _analysisResult?['pageInfo'] as Map<String, dynamic>?;
    final problems = _analysisResult?['problems'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pageInfo != null) ...[
          Text('📄 페이지: ${pageInfo['pageNumber'] ?? '?'}'),
          Text('📚 단원: ${pageInfo['chapterTitle'] ?? '?'}'),
          if (pageInfo['section'] != null)
            Text('📖 대단원: ${pageInfo['section']}'),
        ],
        const SizedBox(height: 8),
        Text('✏️ 문제 수: ${problems.length}개'),
        if (problems.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: problems.take(10).map((p) {
              final prob = p as Map<String, dynamic>;
              return Chip(
                label: Text('${prob['number'] ?? '?'}번'),
                backgroundColor: _getDifficultyColor(prob['difficulty']?.toString()),
                labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          if (problems.length > 10)
            Text('... 외 ${problems.length - 10}개', style: const TextStyle(color: Colors.grey)),
        ],
      ],
    );
  }
  
  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toUpperCase()) {
      case 'BASIC':
        return Colors.green;
      case 'HARD':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
  
  String _subjectName(Subject s) {
    switch (s) {
      case Subject.MATH:
        return '수학';
      case Subject.ENGLISH:
        return '영어';
      case Subject.KOREAN:
        return '국어';
      case Subject.SCIENCE:
        return '과학';
    }
  }
}

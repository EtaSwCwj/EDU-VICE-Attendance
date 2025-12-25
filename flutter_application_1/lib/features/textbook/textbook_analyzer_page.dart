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

  File? _selectedFile;
  String? _fileName;
  bool _isPdf = false;
  Map<String, dynamic>? _analysisResult;
  bool _isLoading = false;
  String? _error;

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
      
      debugPrint('[TextbookAnalyzer] 파일 선택: $_fileName, isPdf: $_isPdf');
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
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToDatabase() async {
    if (_analysisResult == null) return;

    setState(() => _isLoading = true);

    try {
      // 분석 결과에서 pageInfo 추출
      final pageInfo = _analysisResult!['pageInfo'] as Map<String, dynamic>?;

      if (pageInfo == null) {
        throw Exception('분석 결과에 pageInfo가 없습니다');
      }

      // Textbook 모델 생성
      final textbook = Textbook(
        title: pageInfo['chapterTitle']?.toString() ?? '제목 없음',
        subject: Subject.MATH, // 기본값: 수학
        grade: '중2', // 기본값
        semester: '1',
        publisher: '비상교육', // 기본값
        edition: '2024',
        publishYear: 2024,
        totalPages: pageInfo['pageNumber'] as int? ?? 1,
        isVerified: false,
      );

      // Amplify API로 저장
      final request = ModelMutations.create(textbook);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        throw Exception('저장 실패: ${response.errors}');
      }

      debugPrint('[TextbookAnalyzer] 저장 성공: ${response.data?.id}');

      // 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('교재가 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('[TextbookAnalyzer] 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            // 파일 선택 영역
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: _selectedFile != null
                    ? _isPdf
                        // PDF 선택됨
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                                const SizedBox(height: 8),
                                Text(
                                  _fileName ?? 'PDF 파일',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                const Text('탭하여 다른 파일 선택', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          )
                        // 이미지 선택됨
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_selectedFile!, fit: BoxFit.cover),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _fileName ?? '',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                    // 파일 미선택
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('교재 파일을 선택하세요', style: TextStyle(color: Colors.grey)),
                            SizedBox(height: 4),
                            Text('이미지 (JPG, PNG) 또는 PDF', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '분석 결과',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveToDatabase,
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(_analysisResult),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

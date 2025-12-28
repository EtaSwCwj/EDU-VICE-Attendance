import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../shared/services/claude_api_service.dart';

/// 책 페이지 촬영 전용 카메라 (문서 스캐너 기반)
/// - 자동 테두리 감지
/// - 프레임 맞춰야만 촬영 가능
/// - 자동 원근 보정
/// - 페이지 번호 수정 가능
class BookCameraPage extends StatefulWidget {
  const BookCameraPage({super.key});

  @override
  State<BookCameraPage> createState() => _BookCameraPageState();
}

class _BookCameraPageState extends State<BookCameraPage> {
  final _claudeService = ClaudeApiService();
  
  // 1페이지 or 2페이지 모드
  int _pageMode = 1;
  
  // 스캔 결과
  List<String> _scannedImages = [];
  List<int> _detectedPages = [];
  bool _isAnalyzing = false;
  String _analysisStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _scannedImages.isNotEmpty
            ? _buildPreviewScreen()
            : _buildStartScreen(),
      ),
    );
  }

  /// 시작 화면 - 모드 선택 후 스캔
  Widget _buildStartScreen() {
    return Column(
      children: [
        // 상단 바
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
              const Text(
                '📚 책 페이지 촬영',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        
        // 설명
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 아이콘
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.document_scanner, size: 64, color: Colors.teal),
                ),
                const SizedBox(height: 32),
                
                // 설명
                const Text(
                  '자동 문서 인식',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  '카메라가 책 페이지 테두리를 자동으로 감지합니다.\n파란색 테두리가 페이지에 맞춰지면 촬영하세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14, height: 1.5),
                ),
                
                const SizedBox(height: 48),
                
                // 모드 선택
                const Text('촬영할 페이지 수', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeButton(1, '📖 1페이지', '한 장만'),
                    const SizedBox(width: 16),
                    _buildModeButton(2, '📖📖 2페이지', '펼침 촬영'),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // 촬영 시작 버튼
        Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton.icon(
            onPressed: _startScanning,
            icon: const Icon(Icons.camera_alt, size: 28),
            label: const Text('촬영 시작', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  /// 모드 선택 버튼
  Widget _buildModeButton(int mode, String label, String subtitle) {
    final isSelected = _pageMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _pageMode = mode),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade700,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(
              color: isSelected ? Colors.white70 : Colors.grey,
              fontSize: 12,
            )),
          ],
        ),
      ),
    );
  }

  /// 문서 스캔 시작
  Future<void> _startScanning() async {
    try {
      // 스캔할 페이지 수 (2페이지 모드면 2장, 1페이지면 1장)
      final imagePaths = await CunningDocumentScanner.getPictures(
        noOfPages: _pageMode,
        isGalleryImportAllowed: false, // 갤러리 불허 - 반드시 촬영
      );

      if (imagePaths != null && imagePaths.isNotEmpty) {
        setState(() {
          _scannedImages = imagePaths;
        });
        
        // 페이지 번호 인식
        await _analyzePages();
      }
    } catch (e) {
      safePrint('[Scanner] 스캔 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('스캔 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 페이지 번호 인식
  Future<void> _analyzePages() async {
    setState(() {
      _isAnalyzing = true;
      _detectedPages = [];
    });

    try {
      for (int i = 0; i < _scannedImages.length; i++) {
        setState(() => _analysisStatus = '페이지 ${i + 1}/${_scannedImages.length} 인식 중...');
        
        final file = File(_scannedImages[i]);
        final pageNum = await _claudeService.detectPageNumber(file);
        _detectedPages.add(pageNum);
        
        safePrint('[Scanner] 페이지 ${i + 1} → p.$pageNum');
      }

      setState(() {
        _isAnalyzing = false;
        _analysisStatus = '';
      });

    } catch (e) {
      safePrint('[Scanner] 페이지 인식 실패: $e');
      setState(() {
        _isAnalyzing = false;
        _analysisStatus = '인식 실패';
        // 인식 실패 시 0으로 채우기
        while (_detectedPages.length < _scannedImages.length) {
          _detectedPages.add(0);
        }
      });
    }
  }

  /// 페이지 번호 수정 다이얼로그
  Future<void> _editPageNumber(int index) async {
    final controller = TextEditingController(
      text: _detectedPages[index] > 0 ? _detectedPages[index].toString() : '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          '페이지 번호 수정',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '인식된 페이지가 틀렸다면 직접 입력해주세요.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              decoration: InputDecoration(
                hintText: '페이지 번호',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixText: 'p.',
                prefixStyle: const TextStyle(color: Colors.teal, fontSize: 24),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context, value);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _detectedPages[index] = result;
      });
      safePrint('[Scanner] 페이지 ${index + 1} 수동 수정 → p.$result');
    }
  }

  /// 촬영 결과 미리보기 화면
  Widget _buildPreviewScreen() {
    return Column(
      children: [
        // 상단 바
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _retake,
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              const Text(
                '📸 촬영 결과',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        
        // 이미지 미리보기
        Expanded(
          child: PageView.builder(
            itemCount: _scannedImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal, width: 2),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_scannedImages[index]),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // 페이지 표시
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${index + 1}/${_scannedImages.length}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // 인식 결과
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isAnalyzing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(_analysisStatus, style: const TextStyle(color: Colors.white)),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📄 인식된 페이지', 
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '탭하여 수정',
                            style: TextStyle(color: Colors.orange, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _detectedPages.isEmpty
                          ? [const Text('인식 중...', style: TextStyle(color: Colors.grey, fontSize: 16))]
                          : _detectedPages.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final page = entry.value;
                              return GestureDetector(
                                onTap: () => _editPageNumber(idx),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: page > 0 ? Colors.teal : Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: page > 0 ? Colors.teal.shade300 : Colors.orange.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            page > 0 ? 'p.$page' : '?',
                                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.edit, color: Colors.white70, size: 14),
                                        ],
                                      ),
                                      if (_scannedImages.length > 1)
                                        Text(
                                          idx == 0 ? '왼쪽' : '오른쪽',
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                    // 안내 메시지
                    const SizedBox(height: 12),
                    Text(
                      '페이지 번호가 틀렸다면 위 버튼을 탭하여 수정하세요',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
        ),
        
        // 하단 버튼
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 다시 촬영
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retake,
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 촬영'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 확인
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: (_detectedPages.isNotEmpty && !_isAnalyzing) 
                      ? _confirmAndReturn 
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('확인'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 다시 촬영
  void _retake() {
    setState(() {
      _scannedImages = [];
      _detectedPages = [];
    });
  }

  /// 결과 확인 후 돌아가기
  Future<void> _confirmAndReturn() async {
    if (_scannedImages.isEmpty) return;
    
    // 유효한 페이지만 필터링 (0보다 큰 것)
    final validPages = _detectedPages.where((p) => p > 0).toList();
    
    if (validPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('페이지 번호를 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // 2페이지 모드인데 이미지가 2장이면 합치기
    File finalImage;
    
    if (_pageMode == 2 && _scannedImages.length == 2) {
      // 두 이미지를 좌우로 합치기
      final img1 = img.decodeImage(await File(_scannedImages[0]).readAsBytes());
      final img2 = img.decodeImage(await File(_scannedImages[1]).readAsBytes());
      
      if (img1 != null && img2 != null) {
        // 높이를 맞추고 합치기
        final targetHeight = (img1.height + img2.height) ~/ 2;
        final resized1 = img.copyResize(img1, height: targetHeight);
        final resized2 = img.copyResize(img2, height: targetHeight);
        
        final combined = img.Image(
          width: resized1.width + resized2.width,
          height: targetHeight,
        );
        
        img.compositeImage(combined, resized1, dstX: 0, dstY: 0);
        img.compositeImage(combined, resized2, dstX: resized1.width, dstY: 0);
        
        final tempDir = await getTemporaryDirectory();
        final combinedPath = '${tempDir.path}/combined_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(combinedPath).writeAsBytes(img.encodeJpg(combined));
        finalImage = File(combinedPath);
      } else {
        finalImage = File(_scannedImages[0]);
      }
    } else {
      finalImage = File(_scannedImages[0]);
    }
    
    Navigator.pop(context, {
      'image': finalImage,
      'pageMode': _pageMode,
      'pages': validPages,  // 유효한 페이지만 반환
      'individualImages': _scannedImages.map((p) => File(p)).toList(),
    });
  }
}

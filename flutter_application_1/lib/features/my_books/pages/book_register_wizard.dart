import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import '../models/local_book.dart';
import '../data/local_book_repository.dart';

/// 책 등록 위자드 (4단계)
/// - Step 1: 표지 촬영
/// - Step 2: 정보 입력
/// - Step 3: 유사 책 검색
/// - Step 4: 완료
class BookRegisterWizard extends StatefulWidget {
  const BookRegisterWizard({super.key});

  @override
  State<BookRegisterWizard> createState() => _BookRegisterWizardState();
}

class _BookRegisterWizardState extends State<BookRegisterWizard> {
  final _repository = LocalBookRepository();
  final _pageController = PageController();
  final _imagePicker = ImagePicker();

  int _currentStep = 0;

  // Step 1: 표지 이미지
  File? _coverImage;

  // Step 2: 책 정보
  final _titleController = TextEditingController();
  final _publisherController = TextEditingController();
  final _totalPagesController = TextEditingController();
  String _selectedSubject = 'MATH';

  // Step 3: 검색 상태
  bool _isSearching = false;

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _publisherController.dispose();
    _totalPagesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      safePrint('[Register] Step ${_currentStep + 1} → Step ${_currentStep + 2}');
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      safePrint('[Register] Step ${_currentStep + 1} → Step $_currentStep');
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvoked: (bool didPop) {
        if (!didPop && _currentStep > 0) {
          _previousStep();
      }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('책 등록 (${_currentStep + 1}/4)'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
            _buildStep4(),
          ],
        ),
      ),
    );
  }

  /// Step 1: 표지 촬영
  Widget _buildStep1() {
    safePrint('[Register] Step 1 진입');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Step 1: 표지 촬영',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '책 표지를 촬영하거나 갤러리에서 선택해주세요',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // 이미지 표시 영역
          Expanded(
            child: _coverImage == null
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.menu_book,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _coverImage!,
                      fit: BoxFit.contain,
                    ),
                  ),
          ),

          const SizedBox(height: 20),

          // 버튼들
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('카메라'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('갤러리'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 다음 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _coverImage != null ? _nextStep : null,
              child: const Text('다음'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Step 2: 정보 입력
  Widget _buildStep2() {
    safePrint('[Register] Step 2 진입');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Step 2: 책 정보 입력',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '책의 기본 정보를 입력해주세요',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // 제목
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '제목 *',
              border: OutlineInputBorder(),
              hintText: '예: 중학수학 개념끝장내기 1-1',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // 출판사
          TextFormField(
            controller: _publisherController,
            decoration: const InputDecoration(
              labelText: '출판사 *',
              border: OutlineInputBorder(),
              hintText: '예: 천재교육',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // 과목
          DropdownButtonFormField<String>(
            value: _selectedSubject,
            decoration: const InputDecoration(
              labelText: '과목 *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'MATH', child: Text('수학')),
              DropdownMenuItem(value: 'ENGLISH', child: Text('영어')),
              DropdownMenuItem(value: 'KOREAN', child: Text('국어')),
              DropdownMenuItem(value: 'SCIENCE', child: Text('과학')),
            ],
            onChanged: (value) {
              setState(() => _selectedSubject = value!);
            },
          ),
          const SizedBox(height: 16),

          // 총 페이지수
          TextFormField(
            controller: _totalPagesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '총 페이지수 *',
              border: OutlineInputBorder(),
              hintText: '예: 320',
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 32),

          // 버튼들
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('이전'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _validateStep2() ? _nextStep : null,
                  child: const Text('다음'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Step 3: 유사 책 검색
  Widget _buildStep3() {
    safePrint('[Register] Step 3 진입');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Step 3: 유사 책 검색',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '기존에 등록된 유사한 책이 있는지 확인중입니다',
            style: TextStyle(color: Colors.grey),
          ),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSearching)
                    Column(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('검색 중...'),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '유사한 책을 찾지 못했습니다',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '새로운 책으로 등록하시겠습니까?',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // 버튼들
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('이전'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: !_isSearching ? _registerNewBook : null,
                  child: const Text('새로 등록'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Step 4: 완료
  Widget _buildStep4() {
    safePrint('[Register] Step 4 진입');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            '책 등록 완료!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '"${_titleController.text}"가 성공적으로 등록되었습니다',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                safePrint('[Register] 완료 버튼 클릭');
                context.pop(true); // 등록 성공을 알림
              },
              child: const Text('완료'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 카메라에서 이미지 선택
  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _coverImage = File(pickedFile.path);
        });
        safePrint('[Register] 카메라 촬영 완료');
      }
    } catch (e) {
      safePrint('[Register] 카메라 촬영 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카메라 촬영 실패: $e')),
      );
    }
  }

  /// 갤러리에서 이미지 선택
  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _coverImage = File(pickedFile.path);
        });
        safePrint('[Register] 갤러리 선택 완료');
      }
    } catch (e) {
      safePrint('[Register] 갤러리 선택 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('갤러리 선택 실패: $e')),
      );
    }
  }

  /// Step 2 유효성 검사
  bool _validateStep2() {
    return _titleController.text.isNotEmpty &&
        _publisherController.text.isNotEmpty &&
        _totalPagesController.text.isNotEmpty &&
        int.tryParse(_totalPagesController.text) != null;
  }

  /// 새 책 등록
  Future<void> _registerNewBook() async {
    setState(() => _isSearching = true);

    // 잠시 대기 (UX)
    await Future.delayed(const Duration(seconds: 1));

    try {
      final newBook = LocalBook(
        title: _titleController.text,
        publisher: _publisherController.text,
        subject: _selectedSubject,
        totalPages: int.parse(_totalPagesController.text),
        coverImagePath: _coverImage?.path,
      );

      await _repository.saveBook(newBook);
      safePrint('[Register] 책 등록 성공: ${newBook.title}');

      setState(() => _isSearching = false);
      _nextStep();
    } catch (e) {
      safePrint('[Register] 책 등록 실패: $e');
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('책 등록 실패: $e')),
        );
      }
    }
  }
}
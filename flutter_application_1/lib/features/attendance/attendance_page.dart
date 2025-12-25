// lib/features/attendance/attendance_page.dart
//
// 과목/책 데이터소스 분리(Provider) + 최근 저장 목록 로딩
// - SubjectsProvider(LocalSubjectsRepository) 주입
// - DropdownButtonFormField: initialValue 사용
// - 앱 진입 시 로컬 저장소에서 최근 저장 목록 불러오기(listByClass)
// - 저장 성공 시 최근 목록 맨 앞에 즉시 반영

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/usecases/record_attendance.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';

// ▼ 과목/책 Provider & Repository
import '../subjects/subjects_provider.dart';
import '../subjects/local_subjects_repository.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Position? _position;
  LocationPermission? _permission;
  bool _loading = false;

  final List<AttendanceRecord> _recent = [];

  final _formKey = GlobalKey<FormState>();
  bool _filterBySelectedSubject = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    // 최근 저장 목록 로드(재시작 후에도 표시)
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecent(context));
  }

  Future<void> _initLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      _permission = perm;
      if (perm == LocationPermission.denied) {
        final after = await Geolocator.requestPermission();
        _permission = after;
      }
      if (_permission == LocationPermission.deniedForever ||
          _permission == LocationPermission.denied) {
        setState(() {});
        return;
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {});
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() => _position = pos);
    } catch (_) {
      setState(() {}); // 위치 실패는 치명적 아님
    }
  }

  // ▼ 로컬 저장소에서 최근 출석 기록 가져오기 (최신순 상위 20개)
  Future<void> _loadRecent(BuildContext context) async {
    try {
      final repo = context.read<AttendanceRepository>();
      final res = await repo.listByClass('class-dev');
      if (res.isSuccess) {
        final list = res.data ?? <AttendanceRecord>[];
        list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt)); // 최신순
        setState(() {
          _recent
            ..clear()
            ..addAll(list.take(20));
        });
      }
    } catch (_) {
      // 최근 목록은 보조 지표 — 실패해도 화면은 계속 동작
    }
  }

  Future<void> _saveAttendance(BuildContext context) async {
    if (_loading) return;

    final vm = context.read<SubjectsProvider>();
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _loading = true);

    final messenger = ScaffoldMessenger.of(context);
    final uc = context.read<RecordAttendanceUseCase>();

    final now = DateTime.now().toUtc();
    final ts = now.microsecondsSinceEpoch;

    final canUseGeo = _position != null &&
        _permission != LocationPermission.denied &&
        _permission != LocationPermission.deniedForever;

    GeoMeta? geo;
    if (canUseGeo) {
      geo = GeoMeta(
        lat: _position!.latitude,
        lng: _position!.longitude,
        accuracyMeters: _position!.accuracy,
      );
    }

    // 스켈레톤 값(이후 단계에서 실제 값 주입 예정)
    const String studentId = 'student-dev';
    final String? subjectId = vm.selectedSubjectId;
    final String? bookId = vm.selectedBookId;

    String? notes = 'from attendance page';
    if (bookId != null && bookId.isNotEmpty) {
      notes = '$notes | book:$bookId';
    }

    final record = AttendanceRecord(
      id: 'tap-$ts',
      academyId: 'academy-dev',
      classId: 'class-dev',
      studentId: studentId,
      subjectId: subjectId,
      status: AttendanceStatus.present,
      recordedAt: now,
      recordedBy: 'attendance-page',
      geo: geo,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      source: 'ui',
    );

    final res = await uc(record);
    final ok = res.isSuccess;

    if (ok) {
      setState(() {
        _recent.insert(0, record);
        if (_recent.length > 50) _recent.removeRange(50, _recent.length);
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('출석 저장 완료')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('출석 저장 실패: ${res.message ?? '알 수 없음'}')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SubjectsProvider(LocalSubjectsRepository())..load(),
      child: Consumer<SubjectsProvider>(
        builder: (context, vm, _) {
          final hasService = !(_permission == LocationPermission.denied ||
              _permission == LocationPermission.deniedForever);
          final permText = _permission?.name ?? 'unknown';

          final recentView = (_filterBySelectedSubject && vm.selectedSubjectId != null)
              ? _recent.where((r) => r.subjectId == vm.selectedSubjectId).toList()
              : _recent;

          return Scaffold(
            appBar: AppBar(
              title: const Text('출석'),
              actions: [
                // 선택 과목으로만 최근 목록 필터
                Row(
                  children: [
                    const Text('선택 과목만'),
                    Switch.adaptive(
                      value: _filterBySelectedSubject,
                      onChanged: (v) => setState(() => _filterBySelectedSubject = v),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 위치 표시
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _position != null
                                ? '위치: ${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}'
                                : '위치 정보 없음(perm: $permText)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hasService
                                ? '위치 서비스 사용 가능'
                                : '위치 서비스 비활성/권한 미허용',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('과목/책 선택', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),

                    // ▼ 과목/책 선택 폼
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // 과목
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: '과목 (필수)',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: vm.selectedSubjectId,
                            items: vm.subjects
                                .map((s) => DropdownMenuItem<String>(
                                      value: s.id,
                                      child: Text(s.name),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              // ignore: discarded_futures
                              vm.selectSubject(v);
                            },
                            validator: (v) =>
                                (v == null || v.isEmpty) ? '과목을 선택하세요' : null,
                          ),
                          const SizedBox(height: 10),

                          // 책
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: '책 (선택)',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: vm.selectedBookId,
                            items: vm.books
                                .map((b) => DropdownMenuItem<String>(
                                      value: b.id,
                                      child: Text(b.name),
                                    ))
                                .toList(),
                            onChanged: (vm.selectedSubjectId == null)
                                ? null
                                : (v) => vm.selectBook(v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('최근 저장 목록', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: recentView.isEmpty
                          ? const Center(child: Text('최근 저장한 출석 기록이 없습니다.'))
                          : ListView.separated(
                              itemBuilder: (context, index) =>
                                  _RecentListTile(record: recentView[index]),
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemCount: recentView.length,
                            ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : () => _saveAttendance(context),
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(_loading ? '저장 중...' : '출석 저장'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 최근 저장 리스트 아이템
class _RecentListTile extends StatelessWidget {
  final AttendanceRecord record;
  const _RecentListTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final geo = record.geo;
    final hasGeo = geo != null;

    return ListTile(
      leading: const Icon(Icons.fact_check_outlined),
      title: Text('student:${record.studentId} • status:${record.status.name}'),
      subtitle: Text(
        'time:${record.recordedAt.toIso8601String()}'
        '${hasGeo ? ' • geo:${geo.lat.toStringAsFixed(4)},${geo.lng.toStringAsFixed(4)}' : ''}'
        '${(record.notes ?? '').isNotEmpty ? ' • notes:${record.notes}' : ''}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: (record.subjectId != null)
          ? Chip(
              label: Text(record.subjectId!),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }
}

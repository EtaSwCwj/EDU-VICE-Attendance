// lib/features/attendance/attendance_page.dart
//
// 과목/책 데이터소스 분리(Provider) 버전
// - SubjectsProvider(LocalSubjectsRepository) 주입
// - DropdownButtonFormField: initialValue 사용
// - Consumer로 non-null VM 사용

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/usecases/record_attendance.dart';
import '../../domain/entities/attendance_record.dart';

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

  AttendanceRecord? _lastSaved;
  final List<AttendanceRecord> _recent = [];

  final _formKey = GlobalKey<FormState>();
  bool _filterBySelectedSubject = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
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

  Future<void> _saveAttendance(BuildContext context) async {
    if (_loading) return;

    final vm = context.read<SubjectsProvider>();
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _loading = true);

    final messenger = ScaffoldMessenger.of(context);
    final uc = context.read<RecordAttendanceUseCase>();

    // TODO: 로그인/컨텍스트 연동
    const String studentId = 'student-dev';

    final now = DateTime.now().toUtc();
    final ts = now.millisecondsSinceEpoch.toString();

    GeoMeta? geo;
    if (_position != null) {
      geo = GeoMeta(lat: _position!.latitude, lng: _position!.longitude);
    }

    final String? subjectId = vm.selectedSubjectId;
    final String? bookId = vm.selectedBookId;

    String notes = 'from attendance page';
    if (bookId != null) notes = '$notes | book:$bookId';

    final record = AttendanceRecord(
      id: 'tap-$ts',
      academyId: 'academy-dev',
      classId: 'class-dev',
      studentId: studentId,
      subjectId: subjectId,
      status: AttendanceStatus.present,
      recordedAt: now,
      createdAt: now,
      updatedAt: now,
      notes: notes,
      geo: geo,
      recordedBy: 'attendance-page',
      source: 'ui',
    );

    final res = await uc(record);
    final ok = res.isSuccess;

    if (ok) {
      setState(() {
        _lastSaved = record;
        _recent.insert(0, record);
        if (_recent.length > 50) _recent.removeRange(50, _recent.length);
      });
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? '✅ 저장 성공(id: ${record.id})' : '❌ 저장 실패'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // 페이지 내부에서 Provider 주입: 외부(Main) 수정 불필요
    return ChangeNotifierProvider<SubjectsProvider>(
      create: (_) {
        final p = SubjectsProvider(LocalSubjectsRepository());
        // ignore: discarded_futures
        p.load();
        return p;
      },
      child: Consumer<SubjectsProvider>(
        builder: (context, vm, _) {
          final hasService = _position != null;
          final permText = _permission?.toString() ?? 'unknown';

          final List<AttendanceRecord> recentView =
              _filterBySelectedSubject && vm.selectedSubjectId != null
                  ? _recent.where((r) => r.subjectId == vm.selectedSubjectId).toList()
                  : _recent;

          return Scaffold(
            appBar: AppBar(
              title: const Text('출석'),
              actions: [
                Row(
                  children: [
                    const Text('선택 과목만', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _filterBySelectedSubject,
                      onChanged: (v) => setState(() => _filterBySelectedSubject = v),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_lastSaved != null) ...[
                      _RecentSavedCard(record: _lastSaved!),
                      const SizedBox(height: 12),
                    ],

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
                                width: 16, height: 16,
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

// 최근 저장 카드
class _RecentSavedCard extends StatelessWidget {
  final AttendanceRecord record;
  const _RecentSavedCard({required this.record});

  String _fmt(DateTime dt) => dt.toIso8601String();

  @override
  Widget build(BuildContext context) {
    final geo = record.geo;
    final coord =
        (geo != null) ? '${geo.lat.toStringAsFixed(6)}, ${geo.lng.toStringAsFixed(6)}' : 'N/A';
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('최근 저장', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('ID: ${record.id}'),
            Text('시간(UTC): ${_fmt(record.recordedAt)}'),
            Text('좌표: $coord'),
            Text('상태: ${record.status.name}'),
            if (record.subjectId != null) Text('과목: ${record.subjectId}'),
            if ((record.notes ?? '').contains('book:'))
              Text('책: ${(record.notes ?? '').split('book:').last}'),
          ],
        ),
      ),
    );
  }
}

// 최근 목록 타일
class _RecentListTile extends StatelessWidget {
  final AttendanceRecord record;
  const _RecentListTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final geo = record.geo;
    final hasGeo = geo != null;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(
        child: Text(
          (record.subjectId ?? '-').toUpperCase().substring(0, 1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        'student:${record.studentId} • ${record.status.name}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'time:${record.recordedAt.toIso8601String()}'
        '${hasGeo ? ' • geo:${geo.lat.toStringAsFixed(4)},${geo.lng.toStringAsFixed(4)}' : ''}'
        '${(record.notes ?? '').isNotEmpty ? ' • notes:${record.notes}' : ''}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: (record.subjectId != null)
          ? Chip(label: Text(record.subjectId!), side: BorderSide.none, visualDensity: VisualDensity.compact)
          : null,
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/Assignment.dart';

class TeacherAssignmentLocalViewPage extends StatefulWidget {
  final Assignment assignment;

  const TeacherAssignmentLocalViewPage({
    super.key,
    required this.assignment,
  });

  @override
  State<TeacherAssignmentLocalViewPage> createState() => _TeacherAssignmentLocalViewPageState();
}

class _TeacherAssignmentLocalViewPageState extends State<TeacherAssignmentLocalViewPage> {
  bool _loading = true;
  String? _memo;
  bool? _submitted;
  List<String> _photoPaths = const [];

  // 디버그/안전용: 어떤 키를 발견했는지 표시
  List<String> _matchedKeys = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadLocal());
  }

  Future<void> _loadLocal() async {
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final id = widget.assignment.id;

      final keys = prefs.getKeys().toList()..sort();
      final matched = <String>[];

      // 1) assignmentId 포함 키만 후보로
      final candidates = keys.where((k) => k.contains(id)).toList();
      matched.addAll(candidates);

      // 2) memo 후보 찾기
      String? memo;
      for (final k in candidates) {
        final lk = k.toLowerCase();
        if (lk.contains('memo') || lk.contains('note')) {
          final v = prefs.get(k);
          if (v is String && v.trim().isNotEmpty) {
            memo = v;
            break;
          }
        }
      }

      // 3) submitted 후보 찾기
      bool? submitted;
      for (final k in candidates) {
        final lk = k.toLowerCase();
        if (lk.contains('submit') || lk.contains('submitted')) {
          final v = prefs.get(k);
          if (v is bool) {
            submitted = v;
            break;
          }
          if (v is String) {
            final t = v.toLowerCase().trim();
            if (t == 'true' || t == 'false') {
              submitted = (t == 'true');
              break;
            }
          }
          if (v is int) {
            // 1/0 형식 대응
            if (v == 1) {
              submitted = true;
              break;
            }
            if (v == 0) {
              submitted = false;
              break;
            }
          }
        }
      }

      // 4) photo/attachments 후보 찾기 (List<String> / JSON String 모두 대응)
      List<String> photos = [];
      for (final k in candidates) {
        final lk = k.toLowerCase();
        if (lk.contains('photo') || lk.contains('image') || lk.contains('attach')) {
          final v = prefs.get(k);

          if (v is List) {
            photos = v.whereType<String>().toList();
            if (photos.isNotEmpty) break;
          }

          if (v is String && v.trim().isNotEmpty) {
            // JSON array 형식 시도
            final s = v.trim();
            try {
              final decoded = jsonDecode(s);
              if (decoded is List) {
                photos = decoded.whereType<String>().toList();
                if (photos.isNotEmpty) break;
              }
            } catch (_) {
              // 콤마 구분 등 구형 대응(가능하면)
              if (s.contains(',') && !s.contains('{') && !s.contains('[')) {
                final split = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                if (split.isNotEmpty) {
                  photos = split;
                  break;
                }
              }
            }
          }
        }
      }

      // 없는 값들은 “없음”으로 표시만 하고 crash는 내지 않음
      if (!mounted) return;
      setState(() {
        _memo = memo;
        _submitted = submitted;
        _photoPaths = photos;
        _matchedKeys = matched;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memo = null;
        _submitted = null;
        _photoPaths = const [];
        _matchedKeys = const [];
        _loading = false;
      });
    }
  }

  Future<void> _copyId() async {
    await Clipboard.setData(ClipboardData(text: widget.assignment.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID copied')));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('과제 상세(로컬 조회)'),
        actions: [
          IconButton(
            tooltip: 'Copy ID',
            onPressed: _copyId,
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            tooltip: 'Reload',
            onPressed: _loadLocal,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _buildHeaderCard(a),
                const SizedBox(height: 10),
                _buildLocalSummaryCard(),
                const SizedBox(height: 10),
                _buildMemoCard(),
                const SizedBox(height: 10),
                _buildPhotosCard(),
                const SizedBox(height: 10),
                _buildDebugKeysCard(),
              ],
            ),
    );
  }

  Widget _buildHeaderCard(Assignment a) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(Icons.person, 'student: ${a.studentUsername}'),
                _chip(Icons.school, 'teacher: ${a.teacherUsername}'),
                _chip(Icons.flag, 'status: ${a.status.name}'),
                _chip(Icons.key, 'id: ${a.id.substring(0, a.id.length.clamp(0, 10))}...'),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(
              (a.description ?? '').trim().isEmpty ? '(description 없음)' : (a.description ?? '').trim(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalSummaryCard() {
    final submittedText = _submitted == null ? 'UNKNOWN' : (_submitted! ? 'YES' : 'NO');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(Icons.cloud_off, '로컬 데이터(디바이스 공유)'),
            _chip(Icons.assignment_turned_in, '제출: $submittedText'),
            _chip(Icons.notes, '메모: ${(_memo ?? '').trim().isEmpty ? 'NO' : 'YES'}'),
            _chip(Icons.photo, '사진: ${_photoPaths.length}장'),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoCard() {
    final memo = (_memo ?? '').trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('학생 메모(로컬)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (memo.isEmpty)
              const Text('저장된 메모가 없습니다.')
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Text(memo),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('증빙 사진(로컬)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_photoPaths.isEmpty)
              const Text('아직 첨부된 사진이 없습니다.')
            else
              Column(
                children: _photoPaths.map((p) => _photoTile(p)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _photoTile(String path) {
    final f = File(path);
    final exists = f.existsSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!exists)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('파일이 없습니다:\n$path'),
                )
              else
                Image.file(
                  f,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('이미지 로드 실패:\n$path'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  path,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugKeysCard() {
  // “키 이름을 몰라도” 동작시키기 위한 안전장치.
  // 평소엔 굳이 안 봐도 되고, 안 나올 때만 확인용.
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '디버그(매칭된 SharedPreferences 키 + 타입)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),

          if (_matchedKeys.isEmpty)
            const Text('assignmentId를 포함하는 로컬 키를 찾지 못했습니다.')
          else
            FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  );
                }

                final prefs = snap.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _matchedKeys.map((k) {
                    final listValue = prefs.getStringList(k);
                    final strValue = prefs.getString(k);

                    String typeInfo;
                    String preview = '';

                    if (listValue != null) {
                      typeInfo = 'StringList(len=${listValue.length})';
                      if (listValue.isNotEmpty) {
                        final v0 = listValue.first;
                        preview = ' first="${_short(v0)}"';
                      }
                    } else if (strValue != null) {
                      typeInfo = 'String(len=${strValue.length})';
                      preview = ' value="${_short(strValue)}"';
                    } else {
                      typeInfo = 'null';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $k  ->  $typeInfo$preview'),
                    );
                  }).toList(),
                );
              },
            ),

          const SizedBox(height: 6),
          const Text(
            '※ 지금 단계(디바이스 공유)는 “같은 폰에서만” 교사가 볼 수 있게 하는 용도입니다.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

/// 너무 길면 UI 깨져서 앞부분만 보여주기
String _short(String s) {
  final t = s.replaceAll('\n', ' ').trim();
  if (t.length <= 60) return t;
  return '${t.substring(0, 60)}…';
}


  Widget _chip(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

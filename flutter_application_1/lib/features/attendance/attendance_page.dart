import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../shared/services/auth_state.dart';
import '../../shared/models/academy.dart';

class AttendancePage extends StatefulWidget {
  final String role; // owner | teacher | student
  const AttendancePage({required this.role, super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _checking = false;
  String _status = '대기중';
  Position? _pos;
  LocationPermission? _perm;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final academy = auth.currentAcademy;
    final academyName = academy?.name ?? auth.academyName(auth.currentMembership!.academyId);

    final title = switch (widget.role) {
      'owner' => '출석(원장)',
      'teacher' => '출석(선생)',
      _ => '출석(학생)',
    };

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('$title — $academyName', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_academyConfigValid(academy))
          FilledButton.icon(
            icon: _checking
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            onPressed: _checking ? null : () => _checkNow(academy!),
            label: const Text('현재 위치로 출석 확인'),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️ 이 학원에는 지오펜스 좌표가 설정되지 않았습니다.'),
              const SizedBox(height: 6),
              const Text('assets/mock/accounts.json의 academies 항목에 lat/lng/radiusMeters를 추가하세요.'),
            ],
          ),
        const SizedBox(height: 12),
        _InfoRow('권한 상태', _perm?.name ?? '알 수 없음'),
        _InfoRow('현재 상태', _status),
        _InfoRow('위도', _pos != null ? _pos!.latitude.toStringAsFixed(6) : '-'),
        _InfoRow('경도', _pos != null ? _pos!.longitude.toStringAsFixed(6) : '-'),
        const Divider(height: 24),
        Text(
          _academyConfigValid(academy)
              ? '설명\n- 버튼을 누르면 위치 권한을 요청하고, 현재 좌표를 한 번 읽습니다.\n- $academyName의 지오펜스 반경 내면 “지오펜스 안”으로 표시합니다.'
              : '설명\n- 학원 좌표가 없어서 판정을 할 수 없습니다.',
        ),
        if (kIsWeb)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('웹: HTTPS에서만 위치 권한 팝업이 동작합니다(GitHub Pages OK).'),
          ),
      ],
    );
  }

  bool _academyConfigValid(Academy? a) =>
      a != null && a.lat != null && a.lng != null;

  Future<void> _checkNow(Academy academy) async {
    final double centerLat = academy.lat!;
    final double centerLng = academy.lng!;
    final double radius = academy.radiusMeters ?? 200.0;

    setState(() {
      _checking = true;
      _status = '권한/위치 확인중…';
    });

    // 권한
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      setState(() {
        _perm = perm;
        _checking = false;
        _status = '권한 영구 거부됨(설정에서 허용 필요)';
      });
      return;
    }
    _perm = perm;

    // 서비스 켜짐
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _checking = false;
        _status = '위치 서비스 꺼짐(설정에서 켜주세요)';
      });
      return;
    }

    // 현재 위치
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // 기존 medium을 그대로 반영
          // 필요하면 아래 옵션도 사용 가능:
          // timeLimit: Duration(seconds: 10),
          // distanceFilter: 0,
        ),
      );

      _pos = pos;

      // 판정
      final d = _haversineMeters(
        pos.latitude,
        pos.longitude,
        centerLat,
        centerLng,
      );

      final inside = d <= radius;
      setState(() {
        _checking = false;
        _status = inside
            ? '지오펜스 안 (${d.toStringAsFixed(0)}m ≤ ${radius.toStringAsFixed(0)}m)'
            : '지오펜스 밖 (${d.toStringAsFixed(0)}m > ${radius.toStringAsFixed(0)}m)';
      });
    } catch (e) {
      setState(() {
        _checking = false;
        _status = '위치 읽기 실패: $e';
      });
    }
  }

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

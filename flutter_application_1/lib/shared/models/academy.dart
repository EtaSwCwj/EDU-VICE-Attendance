class Academy {
  final String id;
  final String name;
  final String? code;
  final String? address;
  final String? phone;
  final String? description;

  /// 지오펜스 중심 좌표(없을 수도 있음)
  final double? lat;
  final double? lng;

  /// 지오펜스 반경(m). 기본값 null → 코드에서 디폴트 처리
  final double? radiusMeters;

  const Academy({
    required this.id,
    required this.name,
    this.code,
    this.address,
    this.phone,
    this.description,
    this.lat,
    this.lng,
    this.radiusMeters,
  });

  factory Academy.fromJson(Map<String, dynamic> j) => Academy(
        id: j['id'] as String,
        name: j['name'] as String,
        code: j['code'] as String?,
        address: j['address'] as String?,
        phone: j['phone'] as String?,
        description: j['description'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        radiusMeters: (j['radiusMeters'] as num?)?.toDouble(),
      );
}

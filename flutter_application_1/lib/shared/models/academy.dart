class Academy {
  final String id;
  final String name;
  const Academy({required this.id, required this.name});

  factory Academy.fromJson(Map<String, dynamic> j)
    => Academy(id: j['id'] as String, name: j['name'] as String);
}

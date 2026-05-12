class Greenhouse {
  final String id;
  final String name;

  Greenhouse({required this.id, required this.name});

  factory Greenhouse.fromJson(Map<String, dynamic> json) =>
      Greenhouse(id: json['id'] as String, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

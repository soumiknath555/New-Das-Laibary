class ShopModel {
  final String id;
  final String name;
  final String location;
  final DateTime createdAt;
  bool synced;

  ShopModel({
    required this.id,
    required this.name,
    required this.location,
    required this.createdAt,
    required this.synced,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'createdAt': createdAt.toIso8601String(),
    'synced': synced,
  };
}

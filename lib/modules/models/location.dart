class Location {
  final int id;
  final String name;
  final bool isActive;

  Location({
    required this.id,
    required this.name,
    required this.isActive,
  });

  // Create Location from JSON
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  // Convert Location to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_active': isActive,
    };
  }
}
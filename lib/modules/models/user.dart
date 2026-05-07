class User {
  final int id;
  final String name;
  final String email;
  final String userType; // 'passenger', 'driver', or 'admin'
  final String? phone;
  final String? profilePhoto;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.phone,
    this.profilePhoto,
  });

  // Create User from JSON (from API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      userType: json['user_type'],
      phone: json['phone'],
      profilePhoto: json['profile_photo'],
    );
  }

  // Convert User to JSON (for sending to API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'user_type': userType,
      'phone': phone,
      'profile_photo': profilePhoto,
    };
  }
}
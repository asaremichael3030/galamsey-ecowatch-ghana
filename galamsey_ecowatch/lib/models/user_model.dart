class User {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? region;
  final String? district;
  final String? profileImage;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.region,
    this.district,
    this.profileImage,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'citizen',
      region: json['region'],
      district: json['district'],
      profileImage: json['profile_image'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'region': region,
      'district': district,
      'profile_image': profileImage,
      'is_active': isActive,
    };
  }
}
// lib/app/models/User.dart
class User {
  final int? id;
  final String username;
  final String email;
  final String role;
  final String? createdAt;

  User({
    this.id,
    required this.username,
    required this.email,
    this.role = 'user',
    this.createdAt,
  });

  // Factory constructor untuk membuat User dari Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      email: map['email'] as String,
      role: map['role'] as String? ?? 'user',
      createdAt: map['created_at'] as String?,
    );
  }

  // Method untuk convert User ke Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'created_at': createdAt,
    };
  }

  // Method untuk convert User ke JSON
  Map<String, dynamic> toJson() => toMap();

  // Factory constructor untuk membuat User dari JSON
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);

  // Method untuk mengecek apakah user adalah admin
  bool get isAdmin => role == 'admin';

  // Method untuk mengecek apakah user adalah user biasa
  bool get isUser => role == 'user';

  // Method untuk mendapatkan display name
  String get displayName => username;

  // Method untuk mendapatkan role yang di-capitalize
  String get roleDisplay {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'user':
        return 'Pengguna';
      default:
        return role;
    }
  }

  // Override toString untuk debugging
  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, role: $role, createdAt: $createdAt}';
  }

  // Override operator == untuk perbandingan
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.role == role;
  }

  // Override hashCode
  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        email.hashCode ^
        role.hashCode;
  }

  // Method untuk copy user dengan perubahan tertentu
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? role,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
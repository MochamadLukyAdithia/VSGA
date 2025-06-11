class User {
  final int? id;
  final String username;
  final String email;
  final String createdAt;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'created_at': createdAt,
    };
  }
}
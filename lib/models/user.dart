class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.timezone,
    required this.createdAt,
    this.name,
  });

  final String id;
  final String username;
  final String email;
  final String passwordHash;
  final String? name;
  final String timezone;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'timezone': timezone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? passwordHash,
    String? name,
    String? timezone,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class User {
  final String name;
  final String userId;
  final String email;
  final String role;

  User(
      {required this.email,
      required this.role,
      required this.userId,
      required this.name});

  Map<String, dynamic> toJson() => {
        'name': name,
        'userId': userId,
        'email': email,
        'role': role,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        name: json['name'],
        email: json['email'],
        role: json['role'],
        userId: json['userId']);
  }
}

class User {
  final String id;
  final String nom;
  final String email;
  final String role;

  User({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      nom: json['nom'],
      email: json['email'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'email': email,
      'role': role,
    };
  }
}

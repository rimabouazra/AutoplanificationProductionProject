class User {
  final String id;
  final String nom;
  final String email;
  final String? role;
  final String status;

  User({
    required this.id,
    required this.nom,
    required this.email,
    this.role,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      nom: json['nom'],
      email: json['email'],
      role: json['role'],
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'email': email,
      'role': role,
       'status': status,
    };
  }
}

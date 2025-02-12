class User {
  String id;
  String email;
  String password;
  String nom;
  String prenom;
  String role;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.nom,
    required this.prenom,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      email: json['email'],
      password: json['password'],
      nom: json['nom'],
      prenom: json['prenom'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'password': password,
      'nom': nom,
      'prenom': prenom,
      'role': role,
    };
  }
}

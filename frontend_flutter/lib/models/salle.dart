import 'machine.dart';

class Salle {
  String id;
  String nom;
  String type;
  List<Machine>? machines;

  Salle({
    required this.id,
    required this.nom,
    required this.type,
    this.machines,
  });

  factory Salle.fromJson(Map<String, dynamic> json) {
    return Salle(
      id: json['_id'],
      nom: json['nom'],
      type: json['type'],
      machines: json['machines'] != null
          ? (json['machines'] as List).map((m) => Machine.fromJson(m)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'type': type,
      'machines': machines?.map((m) => m.toJson()).toList(),
    };
  }
}

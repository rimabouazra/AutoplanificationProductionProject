class Client {
  String id;  // Changed from String? to String
  String name;

  Client({
    required this.id,  // Now required
    required this.name,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['_id'].toString(),  // Force string conversion
      name: json['name'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}
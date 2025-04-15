class Client {
  final String name;

  Client({ required this.name});

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}

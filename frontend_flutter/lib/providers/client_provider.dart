import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/api_service.dart';

class ClientProvider with ChangeNotifier {
  List<Client> _clients = [];

  List<Client> get clients => _clients;

  Future<void> fetchClients() async {
    _clients = await ApiService.getClients();
    notifyListeners();
  }


  Future<Client> addClient(String name) async {
    final client = await ApiService.addClient(name);
    _clients.add(client);
    notifyListeners();
    return client;
  }
}

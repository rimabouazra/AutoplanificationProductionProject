import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  List<User> get users => _users;

  Future<void> fetchUsers() async {
    try {
      List<User> fetchedUsers = await ApiService.getUsers();
      _users = fetchedUsers;
      notifyListeners();
    } catch (e) {
      print("Erreur lors du chargement des utilisateurs : $e");
    }
  }

  Future<bool> addUser(User user) async {
    bool success = await ApiService.addUser(user);
    if (success) {
      _users.add(user);
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateUser(String id, User user) async {
    bool success = await ApiService.updateUser(id, user);
    if (success) {
      int index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = user;
        notifyListeners();
      }
    }
    return success;
  }

  Future<bool> deleteUser(String id) async {
    bool success = await ApiService.deleteUser(id);
    if (success) {
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
    }
    return success;
  }
}

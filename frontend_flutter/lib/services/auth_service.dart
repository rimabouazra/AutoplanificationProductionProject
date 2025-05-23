import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static final _apiService = ApiService();

   static Future<void> saveUserData(String token, String userId, String role) async {
    try {
      await _storage.write(key: 'token', value: token);
      await _storage.write(key: 'userId', value: userId);
      await _storage.write(key: 'role', value: role);
      
      // Vérification que les données sont bien stockées
      final savedToken = await _storage.read(key: 'token');
      if (savedToken != token) {
        throw Exception('Échec de la sauvegarde du token');
      }
      print('✅ Données utilisateur sauvegardées avec succès');
    } catch (e) {
      print('❌ Erreur critique dans saveUserData: $e');
      throw Exception('Échec de la sauvegarde des données utilisateur');
    }
  }

  static Future<void> clearUserData() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'role');
  }

  static Future<String?> getToken() async {
  try {
    final token = await _storage.read(key: 'token');
    print('Token récupéré du stockage: ${token != null ? "OK" : "NULL"}');
    if (token != null) {
      print('Longueur du token: ${token.length}');
      print('Préfixe du token: ${token.substring(0, 10)}...');
    }
    return token;
  } catch (e) {
    print('Erreur lors de la récupération du token: $e');
    return null;
  }
}


  static Future<String?> getUserId() async {
    return await _storage.read(key: 'userId');
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: 'role');
  }

  static Future<bool> isAdminOrManager() async {
    final role = await getUserRole();
    return role == 'admin' || role == 'manager';
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    return await _apiService.loginUser(email, password);
  }

  static Future<Map<String, dynamic>?> register(String username, String email, String password) async {
    return await _apiService.register(username, email, password);
  }

  static Future<bool> isLoggedIn() async {
    return await getToken() != null;
  }

  static Future<void> logout() async {
  await clearUserData();
}
}
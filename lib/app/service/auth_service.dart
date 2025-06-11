import 'package:vsga/app/models/User.dart';
import 'database_service.dart';

class AuthService {
  final DatabaseService _dbService = DatabaseService();

  Future<AuthResult> login(String username, String password) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Username dan password tidak boleh kosong',
        );
      }

      bool isAuthenticated = await _dbService.authenticateUser(
        username,
        password,
      );

      if (isAuthenticated) {
        Map<String, dynamic>? userData = await _dbService.getUserData(username);
        if (userData != null) {
          User user = User.fromMap(userData);
          return AuthResult(
            success: true,
            user: user,
            message: 'Login berhasil',
          );
        }
      }

      return AuthResult(
        success: false,
        message: 'Username atau password salah',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String message;

  AuthResult({required this.success, this.user, required this.message});
}

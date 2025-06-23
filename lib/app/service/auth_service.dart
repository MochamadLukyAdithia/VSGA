// lib/app/service/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsga/app/models/User.dart';
import 'database_service.dart';

class AuthService {
  final DatabaseService _dbService = DatabaseService();
  
  // Keys for SharedPreferences
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  static const String _roleKey = 'role';
  static const String _isLoggedInKey = 'is_logged_in';

  Future<AuthResult> login(String username, String password, String role) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Username dan password tidak boleh kosong',
        );
      }

      // Authenticate user dengan role
      bool isAuthenticated = await _dbService.authenticateUserWithRole(
        username,
        password,
        role,
      );

      if (isAuthenticated) {
        Map<String, dynamic>? userData = await _dbService.getUserDataWithRole(username, role);
        if (userData != null) {
          User user = User.fromMap(userData);
          
          // Simpan session user dengan role
          await _saveUserSession(user, role);
          
          return AuthResult(
            success: true,
            user: user,
            message: 'Login berhasil',
          );
        }
      }

      return AuthResult(
        success: false,
        message: 'Username atau password salah, atau role tidak sesuai',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  // Fungsi untuk menyimpan session user dengan role
  Future<void> _saveUserSession(User user, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userIdKey, user.id ?? 0);
      await prefs.setString(_usernameKey, user.username);
      await prefs.setString(_emailKey, user.email);
      await prefs.setString(_roleKey, role);
      await prefs.setBool(_isLoggedInKey, true);
    } catch (e) {
      print('Error saving user session: $e');
    }
  }

  // Fungsi untuk logout
  Future<AuthResult> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Hapus semua data session
      await prefs.remove(_userIdKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_roleKey);
      await prefs.setBool(_isLoggedInKey, false);
      
      return AuthResult(
        success: true,
        message: 'Logout berhasil',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Gagal logout: ${e.toString()}',
      );
    }
  }

  // Fungsi untuk mengecek apakah user sudah login
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Fungsi untuk mendapatkan role user yang sedang login
  Future<String?> getCurrentUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool loggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (!loggedIn) return null;
      
      return prefs.getString(_roleKey);
    } catch (e) {
      return null;
    }
  }

  // Fungsi untuk mengecek apakah user adalah admin
  Future<bool> isAdmin() async {
    try {
      final role = await getCurrentUserRole();
      return role == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Fungsi untuk mengecek apakah user adalah user biasa
  Future<bool> isUser() async {
    try {
      final role = await getCurrentUserRole();
      return role == 'user';
    } catch (e) {
      return false;
    }
  }

  // Fungsi untuk mendapatkan current user dari session
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool loggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (!loggedIn) return null;
      
      int? userId = prefs.getInt(_userIdKey);
      String? username = prefs.getString(_usernameKey);
      String? email = prefs.getString(_emailKey);
      String? role = prefs.getString(_roleKey);
      
      if (userId != null && username != null && email != null) {
        return User(
          id: userId,
          username: username,
          email: email,
          role: role ?? 'user',
        );
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Fungsi untuk mengubah password
  Future<AuthResult> changePassword(String username, String oldPassword, String newPassword) async {
    try {
      // Get current user role
      String? currentRole = await getCurrentUserRole();
      if (currentRole == null) {
        return AuthResult(
          success: false,
          message: 'User tidak dalam sesi login',
        );
      }

      // Verifikasi password lama dengan role
      bool isOldPasswordCorrect = await _dbService.authenticateUserWithRole(username, oldPassword, currentRole);
      
      if (!isOldPasswordCorrect) {
        return AuthResult(
          success: false,
          message: 'Password lama tidak benar',
        );
      }

      // Update password di database
      bool passwordUpdated = await _dbService.updatePassword(username, newPassword, currentRole);
      
      if (passwordUpdated) {
        return AuthResult(
          success: true,
          message: 'Password berhasil diubah',
        );
      }
      
      return AuthResult(
        success: false,
        message: 'Gagal mengubah password',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  // Fungsi untuk register user baru (khusus admin yang bisa menambah user)
  Future<AuthResult> registerUser({
    required String username,
    required String email,
    required String password,
    required String role,
    String? adminUsername,
  }) async {
    try {
      // Cek apakah yang melakukan register adalah admin (kecuali untuk register admin pertama)
      if (role == 'admin' && adminUsername != null) {
        bool isAdminAuthenticated = await isAdmin();
        if (!isAdminAuthenticated) {
          return AuthResult(
            success: false,
            message: 'Hanya admin yang dapat menambahkan admin baru',
          );
        }
      }

      // Cek apakah username atau email sudah ada
      bool usernameExists = await _dbService.checkUsernameExists(username, role);
      if (usernameExists) {
        return AuthResult(
          success: false,
          message: 'Username sudah digunakan',
        );
      }

      bool emailExists = await _dbService.checkEmailExists(email, role);
      if (emailExists) {
        return AuthResult(
          success: false,
          message: 'Email sudah digunakan',
        );
      }

      // Insert user baru
      bool userCreated = await _dbService.createUser(
        username: username,
        email: email,
        password: password,
        role: role,
      );

      if (userCreated) {
        return AuthResult(
          success: true,
          message: 'User berhasil didaftarkan',
        );
      }

      return AuthResult(
        success: false,
        message: 'Gagal mendaftarkan user',
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
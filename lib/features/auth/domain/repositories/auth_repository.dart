import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  Future<AppUser> login({required String email, required String password});
  Future<AppUser> register({required String name, required String email, required String password});
  Future<void> logout();
  Future<void> sendPasswordResetEmail(String email);
  AppUser? get currentUser;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/errors/app_exception.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepositoryImpl(),
);

// Simple stream of the raw Firebase Auth user — used only for the router listenable
// This resolves instantly (Firebase Auth is synchronous after init)
final firebaseAuthUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Full AppUser stream (with Firestore fetch)
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

// Auth notifier for login/register/logout actions
class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _repo.authStateChanges.listen(
      (user) => state = AsyncValue.data(user),
      onError: (e) => state = AsyncValue.data(null),
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.login(email: email, password: password);
      state = AsyncValue.data(user);
    } on AuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(
        AuthException(message: 'An unexpected error occurred.'),
        StackTrace.current,
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.register(name: name, email: email, password: password);
      state = AsyncValue.data(user);
    } on AuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(
        AuthException(message: 'Registration failed. Please try again.'),
        StackTrace.current,
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _repo.sendPasswordResetEmail(email);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

// Convenient current user provider
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
});

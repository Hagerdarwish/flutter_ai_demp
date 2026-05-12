import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Auth state stream — used by SplashPage & providers
  // ---------------------------------------------------------------------------
  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        return await _fetchOrCreateUser(user);
      } catch (_) {
        // Firestore unavailable — fall back to Auth data so app still works
        return _userFromFirebaseUser(user);
      }
    });
  }

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _userFromFirebaseUser(user);
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------
  @override
  Future<AppUser> login({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      try {
        return await _fetchOrCreateUser(cred.user!);
      } catch (_) {
        return _userFromFirebaseUser(cred.user!);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapAuthError(e.code), code: e.code);
    } catch (e) {
      throw AuthException(message: 'Login failed. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------
  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create Firebase Auth account
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Update display name in Firebase Auth
      await cred.user!.updateDisplayName(name.trim());

      final appUser = AppUser(
        id: cred.user!.uid,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Save profile to Firestore (best-effort — don't fail registration if this fails)
      try {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(appUser.id)
            .set(_userToMap(appUser));
      } on FirebaseException catch (e) {
        // Log but don't throw — user IS registered in Auth
        // They can still use the app; Firestore write will be retried on next login
        print('[MeetFlow] Firestore profile write failed: ${e.code} — ${e.message}');
      }

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapAuthError(e.code), code: e.code);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: 'Registration failed. Please try again. ($e)');
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------
  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapAuthError(e.code), code: e.code);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Fetch from Firestore, or create the doc if it doesn't exist yet.
  Future<AppUser> _fetchOrCreateUser(User firebaseUser) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      return _userFromMap(doc.data()!);
    }

    // Firestore doc missing — create it now (e.g. first login after migration)
    final appUser = _userFromFirebaseUser(firebaseUser);
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .set(_userToMap(appUser));
    return appUser;
  }

  /// Build an AppUser purely from FirebaseAuth data (no Firestore needed).
  AppUser _userFromFirebaseUser(User user) {
    return AppUser(
      id: user.uid,
      name: user.displayName ?? user.email?.split('@').first ?? 'User',
      email: user.email ?? '',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _userToMap(AppUser user) => {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'updatedAt': Timestamp.fromDate(user.updatedAt),
      };

  AppUser _userFromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }
}

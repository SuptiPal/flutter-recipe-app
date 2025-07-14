import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<User?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null && user.email == 'suptipal03@gmail.com') {
      await user.updateDisplayName('Admin');
    }
    return user;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Force Admin name if email matches
      final isAdmin = email.trim().toLowerCase() == 'suptipal03@gmail.com';
      final nameToSet = isAdmin ? 'Admin' : displayName;

      // Update display name in Firebase Auth
      await credential.user?.updateDisplayName(nameToSet);
      await credential.user?.reload();

      // Save user profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user?.uid)
          .set({
        'uid': credential.user?.uid,
        'email': email.trim(),
        'displayName': nameToSet,
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null &&
          credential.user!.email == 'suptipal03@gmail.com') {
        await credential.user!.updateDisplayName('Admin');
        await credential.user!.reload();
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}
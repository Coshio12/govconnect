import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../firebase_init.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<User?> get authStateChanges {
    if (!firebaseInitialized) {
      return Stream.value(null);
    }
    return _auth.authStateChanges();
  }

  User? get currentUser => firebaseInitialized ? _auth.currentUser : null;

  /// Login con Google
  Future<UserCredential?> signInWithGoogle() async {
    if (!firebaseInitialized) return null;
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      await _ensureUserProfile(result.user!);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Crea o actualiza el perfil en Firestore al primer login
  Future<void> _ensureUserProfile(User user) async {
    final docRef =
        _db.collection(AppConstants.colUsuarios).doc(user.uid);
    final snap = await docRef.get();

    if (!snap.exists) {
      await docRef.set({
        'email': user.email ?? '',
        'nombre': user.displayName ?? 'Sin nombre',
        'foto': user.photoURL,
        'rol': AppConstants.rolUsuario,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Obtiene el rol del usuario actual
  Future<String> getUserRol(String uid) async {
    try {
      final doc =
          await _db.collection(AppConstants.colUsuarios).doc(uid).get();
      if (doc.exists) {
        return doc.data()?['rol'] ?? AppConstants.rolUsuario;
      }
      return AppConstants.rolUsuario;
    } catch (_) {
      return AppConstants.rolUsuario;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    if (firebaseInitialized) await _auth.signOut();
  }
}

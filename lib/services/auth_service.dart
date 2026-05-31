import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream para escuchar cambios de sesión
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

    Future<UserCredential?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    }
  }


  // Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Eliminar cuenta
  Future<void> deleteAccount(FirestoreService firestoreService) async {
    await firestoreService.eliminarTodosLosDatos();
    await _auth.currentUser?.delete();
  }

  // Olvidé contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    }
  }

  // Manejo de errores en español
  String _handleError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intentá más tarde.';
      case 'requires-recent-login':
        return 'Necesitás volver a iniciar sesión para hacer esto.';
      default:
        return 'Ocurrió un error. Intentá de nuevo.';
    }
  }
}
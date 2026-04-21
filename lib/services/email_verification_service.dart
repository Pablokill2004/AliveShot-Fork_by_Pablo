import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> sendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
    } catch (e) {
      throw Exception('Error al enviar el correo de verificación: $e');
    }
  }

  static Future<bool> isEmailVerified(User user) async {
    try {
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      throw Exception('Error al verificar el correo: $e');
    }
  }

  static Future<void> waitForEmailVerification(User user, {Duration timeout = const Duration(minutes: 5)}) async {
    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < timeout) {
      if (await isEmailVerified(user)) {
        return;
      }
      await Future.delayed(const Duration(seconds: 3));
    }
    throw Exception('El correo no ha sido verificado en el tiempo límite.');
  }
}
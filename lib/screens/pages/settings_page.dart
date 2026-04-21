import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:alive_shot/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:alive_shot/screens/common/theme/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    try {
      await FirebaseAuth.instance.signOut();
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    //Modo obscuro
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Inicio', style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: const Color(0x00003153),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("Modo obscuro"),
            value: themeProvider.themeMode == ThemeMode.dark,

            onChanged: (value) {
              themeProvider.toggleTheme(value);
              colorScheme.secondary;
            },
          ),
          Center(
            child: ElevatedButton(
              onPressed: () => _signOut(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: textTheme.bodyMedium?.color,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:alive_shot/screens/common/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:alive_shot/screens/pages/pages.dart'; //Clase quien contiene todas las paginas
import 'package:google_fonts/google_fonts.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            title: 'AliveShot',
            theme: ThemeData(
              colorScheme: ThemeProvider.getTheme(false).colorScheme,
              useMaterial3: true,
              textTheme: GoogleFonts.interTextTheme(),
            ),
            darkTheme: ThemeProvider.getTheme(true),
            themeMode: themeProvider.themeMode,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  return const HomePage();
                }
                return const LoginScreen();
              },
            ),
            routes: {
              '/register': (context) => const RegisterScreen(),
              '/login': (context) => const LoginScreen(),
              '/notifications_page': (context) => const NotificationsPage(),
            },
          );
        },
      ),
    );
  }
}

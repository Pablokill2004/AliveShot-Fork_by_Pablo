import 'package:flutter/material.dart';
import 'package:alive_shot/screens/common/common.dart';
import 'package:alive_shot/screens/pages/pages.dart';
import 'package:alive_shot/screens/widgets/widgets.dart';

// Actua como pantalla de carga, que redirige principalmente a HomePage
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  void splashing(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () async {
        if (context.mounted) context.push(route: HomePage.route());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    splashing(context);

    return const Scaffold(body: Center(child: AppLogo()));
  }
}

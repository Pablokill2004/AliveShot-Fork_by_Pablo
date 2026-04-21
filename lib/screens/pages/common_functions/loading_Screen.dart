import 'package:flutter/material.dart';
Widget loadingScreen(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary,
            colorScheme.primary, // Azul prusia
          ],
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: colorScheme.onPrimary,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
        ),
      ),
    );
  }
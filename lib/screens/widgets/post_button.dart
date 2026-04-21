import 'package:flutter/material.dart';

class PostButton extends StatelessWidget {
  const PostButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.padding,
    this.onTextTap,
  });

  final Icon icon;
  final String text;
  final VoidCallback onTap;
  final EdgeInsets? padding;
  final VoidCallback? onTextTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onTextTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Más margen
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith( 
                      color: onTextTap != null ? theme.colorScheme.onPrimary : null,
                      fontWeight: FontWeight.bold, 
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
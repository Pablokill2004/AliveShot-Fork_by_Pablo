import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';

class UserStoryAvatar extends StatelessWidget {
  const UserStoryAvatar({
    super.key,
    required this.userStory,
    required this.onTap,
    required this.avatarRadius,
    required this.squareSize,
  });

  final UserStory userStory;
  final VoidCallback onTap;
  //tamaño del radio del avatar
  final double avatarRadius;
  final double squareSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.fromSize(
          size:  Size.square(squareSize),

          //Grosor del borde
          child:  CircularProgressIndicator(value: 1, strokeWidth: 5, color: Theme.of(context).colorScheme.secondary),
        ),
        CircleAvatar(
          radius: avatarRadius,
          backgroundImage: userStory.owner.profileImage.isNotEmpty
              ? NetworkImage(userStory.owner.profileImage)
              : null,
          backgroundColor: userStory.owner.profileImage.isEmpty
              ? theme.colorScheme.primary
              : null, // Placeholder si vacío
          child: userStory.owner.profileImage.isEmpty
              ? Text(
                  userStory.owner.username.isNotEmpty
                      ? userStory.owner.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: theme.colorScheme.primary.withAlpha(50),
              borderRadius: BorderRadius.circular(100),
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
}

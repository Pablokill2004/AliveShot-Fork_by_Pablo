import 'package:flutter/material.dart';
import 'package:alive_shot/screens/common/common.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/widgets/user_story_avatar.dart';
import 'package:alive_shot/screens/pages/user_story_page.dart';

class UserStoryTile extends StatelessWidget {
  const UserStoryTile({super.key, required this.userStory});

  final UserStory userStory; 

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          child: UserStoryAvatar(
            userStory: userStory,
            onTap: () => context.push(route: UserStoryPage.route(0, userStories: [userStory])),
            avatarRadius: 30,
            squareSize: 65,
          ),
        ),
        SizedBox(
          width: 75,
          child: Text(
            userStory.owner.username,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
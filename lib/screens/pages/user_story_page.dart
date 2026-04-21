import 'package:flutter/material.dart';
import 'package:alive_shot/screens/common/common.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/widgets/widgets.dart';
import 'package:story/story_page_view.dart';

class UserStoryPage extends StatelessWidget {
  const UserStoryPage({
    super.key,
    required this.initialIndex,
    this.userStories,
  });

  static MaterialPageRoute route(
    int initialIndex, {
    List<UserStory>? userStories,
  }) {
    return MaterialPageRoute(
      builder: (_) {
        return UserStoryPage(
          initialIndex: initialIndex,
          userStories: userStories ?? UserStory.dummyUserStories,
        );
      },
    );
  }

  final int initialIndex;
  final List<UserStory>? userStories;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserStory>>(
      future: userStories != null
          ? Future.value(userStories!)
          : UserStory.loadUserStories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty ||
            snapshot.data!.any((userStory) => userStory.stories.isEmpty)) {
          return const Scaffold(
            body: Center(child: Text('No hay historias disponibles')),
          );
        }
        final stories = snapshot.data!;
        return Scaffold(
          body: StoryPageView(
            initialPage: initialIndex,
            itemBuilder: (_, pageIndex, storyIndex) {
              final UserStory userStory = stories[pageIndex];
              final Story story = userStory.stories[storyIndex];
              return _storyImage(story);
            },
            gestureItemBuilder: (context, pageIndex, _) {
              final UserStory userStory = stories[pageIndex];
              return _storyAppBar(context, userStory);
            },
            pageLength: stories.length,
            storyLength: (pageIndex) {
              return stories[pageIndex].stories.isNotEmpty
                  ? stories[pageIndex].stories.length
                  : 0;
            },
            onPageLimitReached: () => context.pop(),
          ),
        );
      },
    );
  }

  Widget _storyAppBar(BuildContext context, UserStory userStory) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: const EdgeInsets.only(top: 38, bottom: 8),
        color: Colors.black45,
        child: Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              color: Colors.white,
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => context.pop(),
            ),
            Flexible(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: userStory.owner.profileImage.isNotEmpty
                      ? NetworkImage(userStory.owner.profileImage)
                      : null,
                  backgroundColor:
                      theme.colorScheme.primary, // Placeholder si está vacío
                  child: userStory.owner.profileImage.isEmpty
                      ? Text(
                          userStory.owner.username.isNotEmpty
                              ? userStory.owner.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                title: Text(
                  userStory.owner.username,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyImage(Story story) {
    return Container(
      color: Colors.black87,
      child: Stack(
        children: [
          Positioned.fill(
            child: ResponsivePadding(
              child: Image.network(
                story.storyImage,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 96,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              color: Colors.black45,
              child: Center(
                child: Text(
                  story.caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

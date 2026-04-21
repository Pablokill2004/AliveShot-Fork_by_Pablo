import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/widgets/widgets.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:alive_shot/screens/pages/common_functions/loading_Screen.dart';


class UserStoriesListView extends StatefulWidget {
  const UserStoriesListView({
    super.key,
  });

  @override
  State<UserStoriesListView> createState() => _UserStoriesListViewState();
}

class _UserStoriesListViewState extends State<UserStoriesListView> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isLoading = false;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    final  colorScheme = Theme.of(context).colorScheme;
    if (isLoading) {
      return Scaffold(body: loadingScreen(context));
    }
    return SizedBox(
      height: 110,
      child: FutureBuilder<Map<String, dynamic>>(
        // load both following stories and current user data
        future: () async {
          final uid = auth.FirebaseAuth.instance.currentUser?.uid;
          final stories = await UserStory.loadFollowingUserStories();
          Map<String, dynamic> userData = {};
          if (uid != null) {
            userData = await ApiService.getUser(uid);
          }
          final user = userData.isNotEmpty ? User.fromMap(userData) : User.dummyUsers[0];
          return {'stories': stories, 'user': user};
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
            ));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar historias: ${snapshot.error}'),
            );
          }

          final followingStories = (snapshot.data?['stories'] as List<UserStory>?)
                  ?.where((s) => s.stories.isNotEmpty)
                  .toList() ??
              [];
          final currentUser = snapshot.data?['user'] as User? ?? User.dummyUsers[0];

          final totalItems = 1 + followingStories.length;

          return ListView.separated(
            itemCount: totalItems,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return SizedBox(
                  width: 75,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.fromSize(
                        size: const Size.square(65),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: currentUser.profileImage.isNotEmpty
                              ? NetworkImage(currentUser.profileImage)
                              : null,
                          backgroundColor: currentUser.profileImage.isEmpty
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          child: currentUser.profileImage.isEmpty
                              ? Text(
                                  currentUser.username.isNotEmpty
                                      ? currentUser.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.username,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }

              final userStory = followingStories[index - 1];
              return SizedBox(
                width: 75,
                child: UserStoryTile(userStory: userStory),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:alive_shot/screens/common/build_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/widgets/widgets.dart';
import 'package:alive_shot/screens/pages/pages.dart';

class BannerAndProfilePicture extends StatefulWidget {
  const BannerAndProfilePicture({
    super.key,
    required this.context,
    required this.userfid,
    this.story,
    required this.postsReloadToken,
    required this.userPostsFuture,
    required this.posts,
    this.storyReloadToken = 0,
    this.firebaseUid = '',
  });

  final BuildContext context;
  final User userfid;
  final UserStory? story;
  final int postsReloadToken;
  final int storyReloadToken;
  final Future<List<Map<String, dynamic>>> userPostsFuture;
  final List<Post> posts;
  final String firebaseUid;

  @override
  State<BannerAndProfilePicture> createState() =>
      _BannerAndProfilePictureState();
}

class _BannerAndProfilePictureState extends State<BannerAndProfilePicture> {
  @override
  void didUpdateWidget(covariant BannerAndProfilePicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger reload when story token changes (e.g., on refresh)
    if (widget.storyReloadToken != oldWidget.storyReloadToken) {
      // Parent requested reload - trigger rebuild
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Column(
          children: [
            widget.userfid.bannerImage.isEmpty
                ? Container(
                    height: 150,
                    color: const Color.fromARGB(255, 113, 113, 113),
                  )
                : Container(
                    height: 150,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(widget.userfid.bannerImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 10,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.onPrimary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${widget.userfid.followersCount}",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textTheme.bodyMedium?.color,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Seguidores",
                        style: TextStyle(
                          color: textTheme.bodyMedium?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: colorScheme.onPrimary,
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: widget.userPostsFuture,
                    builder: (context, snapshot) {
                      final postCount =
                          snapshot.data?.length ?? widget.posts.length;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$postCount",
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textTheme.bodyMedium?.color,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Publicaciones",
                            style: TextStyle(
                              color: textTheme.bodyMedium?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: colorScheme.onPrimary,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FollowingListPage(
                            firebaseUid: widget.userfid.firebaseUid,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${widget.userfid.followingCount}",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textTheme.bodyMedium?.color,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Siguiendo",
                          style: TextStyle(
                            color: textTheme.bodyMedium?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        if (widget.story != null && widget.story!.stories.isNotEmpty)
          Positioned(
            top: 70,
            child: SizedBox(
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: UserStoryAvatar(
                  userStory: widget.story!,
                  onTap: () {
                    if (widget.story!.stories.isNotEmpty) {
                      context.push(
                        route: UserStoryPage.route(
                          0,
                          userStories: [widget.story!],
                        ),
                      );
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No hay historias para mostrar'),
                        ),
                      );
                    }
                  },
                  avatarRadius: 45,
                  squareSize: 95,
                ),
              ),
            ),
          )
        else
          Positioned(
            top: 70,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: Colors.grey[300],
              ),
              child: widget.userfid.profileImage.isEmpty
                  ? const Icon(
                      Icons.account_circle,
                      size: 100,
                      color: Colors.grey,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.network(
                        widget.userfid.profileImage,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

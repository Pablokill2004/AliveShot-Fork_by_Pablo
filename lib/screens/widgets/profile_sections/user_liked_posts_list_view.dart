import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/widgets/post_card.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:iconsax/iconsax.dart';

class UserLikedPostsListView extends StatefulWidget {
  final String firebaseUid;
  const UserLikedPostsListView({super.key, required this.firebaseUid});

  @override
  State<UserLikedPostsListView> createState() => _UserLikedPostsListViewState();
}

class _UserLikedPostsListViewState extends State<UserLikedPostsListView> {
  late Future<List<Map<String, dynamic>>> _userLikedPostsFuture;

  @override
  void initState() {
    super.initState();
    _userLikedPostsFuture = ApiService.getUserLikedPosts(widget.firebaseUid);
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userLikedPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(
            color: colorScheme.onPrimary,
          ));
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar publicaciones: ${snapshot.error}',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final postsData = snapshot.data ?? [];
        if (postsData.isEmpty) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.heart_slash, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No has dado like a ninguna publicación',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Encuentra publicaciones que te gusten!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          itemCount: postsData.length,
          separatorBuilder: (context, index) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 4),
            );
          },
          itemBuilder: (context, index) {
            final postData = postsData[index];
            final int postId = postData['id'] ?? 0;

            return FutureBuilder<List<Comment>>(
              future: ApiService.getPostComments(postId),
              builder: (context, commentsSnapshot) {
                final comments = commentsSnapshot.data ?? <Comment>[];

                return FutureBuilder<int>(
                  future: ApiService.getLikeCount(postId),
                  builder: (context, likeCountSnapshot) {
                    final likeCount = likeCountSnapshot.data ?? 0;
                    final firebaseUid =
                        auth.FirebaseAuth.instance.currentUser!.uid;
                    return FutureBuilder<bool>(
                      future: ApiService.checkUserLiked(postId, firebaseUid),
                      builder: (context, isLikedSnapshot) {
                        final isLiked = isLikedSnapshot.data ?? false;

                        final post = Post(
                          owner: User(
                            firebaseUid: postData['firebase_uid'] ?? '',
                            profileImage: postData['profile_image'] ?? '',
                            bannerImage: '',
                            username: postData['username'] ?? '',
                            fullname:
                                '${postData['name'] ?? ''} ${postData['last_name'] ?? ''}',
                            bio: '',
                            followersCount: 0,
                            followingCount: 0,
                            email: '',
                            name: postData['name'] ?? '',
                            lastname: postData['last_name'] ?? '',
                            birthday: '',
                            gender: '',
                            title: '',
                            address: '',
                            phone: '',
                            chlallengesCreated: 0,
                            challengesWon: 0,
                            streak: 0,
                          ),
                          title: postData['title'],
                          description: postData['description'],
                          categoryId: postData['category_id'],
                          postImage: postData['content_url'] ?? '',
                          contentType: postData['content_type'] ?? 'image',
                          comments: comments,
                          date: _formatDate(postData['created_at'] ?? ''),
                          likeCount: likeCount,
                          saveCount: 0,
                          isLiked: isLiked,
                          isSaved: false,
                        );

                        return PostCard(
                          firebaseUid: widget.firebaseUid,
                          post: post,
                          postId: postId,
                          key: ValueKey('liked_post_$postId'),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} | ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

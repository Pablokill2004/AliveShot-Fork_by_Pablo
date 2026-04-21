import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:alive_shot/services/api_services/api_service.dart';

import 'package:iconsax/iconsax.dart';

class PostsListView extends StatefulWidget {
  const PostsListView({super.key, required this.theme, this.reloadTrigger = 0});

  final ThemeData theme;
  final int reloadTrigger;

  @override
  State<PostsListView> createState() => _PostsListViewState();
}

class _PostsListViewState extends State<PostsListView> {
  late Future<FeedResponse> _userPostsFuture;
  final String firebaseUid = auth.FirebaseAuth.instance.currentUser!.uid;
  
  @override
  void initState() {
    super.initState();
    _userPostsFuture = ApiService.getUserFeed(firebaseUid);
  }

  @override
  void didUpdateWidget(covariant PostsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloadTrigger != oldWidget.reloadTrigger) {
      // Parent requested reload
      setState(() {
        _userPostsFuture = ApiService.getUserFeed(firebaseUid);
      });
    }
  }

  Future<Map<String, dynamic>> _loadPostData(Map<String, dynamic> postData) async {
    final int postId = postData['post_id'] ?? postData['id'] ?? 0;
    
    final comments = await ApiService.getPostComments(postId);
    final likeCount = await ApiService.getLikeCount(postId);
    final isLiked = await ApiService.checkUserLiked(postId, firebaseUid);
    
    return {
      ...postData,
      'comments': comments,
      'likeCount': likeCount,
      'isLiked': isLiked,
    };
  }

  @override
  Widget build(BuildContext context) {
    final  colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<FeedResponse>(
      future: _userPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return  Center(child: CircularProgressIndicator(
            color: colorScheme.onPrimary,
          ));
        }

        if (snapshot.hasError) {
          return ErrorLoadingPostsMessage(snapshot: snapshot);
        }
        final postsData = snapshot.data?.posts ?? [];

        if (postsData.isEmpty) {
          return FollowUsersMessage(widget: widget);
        } else {
          return ListView.separated(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: postsData.length,
            separatorBuilder: (context, index) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 4),
              );
            },
            itemBuilder: (context, index) {
              final postData = postsData[index];
              final int postId = postData['post_id'] ?? postData['id'] ?? 0;

              return FutureBuilder<Map<String, dynamic>>(
                future: _loadPostData(postData),
                builder: (context, enrichedSnapshot) {
                  if (enrichedSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                      ),
                    );
                  }

                  if (enrichedSnapshot.hasError) {
                    return const SizedBox.shrink();
                  }

                  final enrichedData = enrichedSnapshot.data ?? {};
                  final comments = enrichedData['comments'] as List<Comment>? ?? <Comment>[];
                  final likeCount = enrichedData['likeCount'] as int? ?? 0;
                  final isLiked = enrichedData['isLiked'] as bool? ?? false;

                  final post = Post(
                    owner: User(
                      firebaseUid: postData['firebase_uid'],
                      profileImage: postData['user_image'] ?? '',
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
                    title: postData['title'] ?? 'Sin título',
                    description: postData['description'] ?? '',
                    categoryId: postData['category_id'] ?? 0,
                    postImage: postData['content_url'] ?? '',
                    contentType:
                        postData['content_type'] ?? 'image',
                    comments: comments,
                    date: _formatDate(postData['created_at'] ?? ''),
                    likeCount: likeCount,
                    saveCount: 0,
                    isLiked: isLiked,
                    isSaved: false,
                  );

                  return PostCard(
                    firebaseUid: firebaseUid,
                    post: post,
                    postId: postId,
                    key: ValueKey('post_$postId'),
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    // devolver fecha junto con la hora
    return '${date.day}/${date.month}/${date.year} | ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class FollowUsersMessage extends StatelessWidget {
  const FollowUsersMessage({super.key, required this.widget});

  final PostsListView widget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.pen_close2, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Sigue a usuarios para ver sus publicaciones aquí.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class ErrorLoadingPostsMessage extends StatelessWidget {
  const ErrorLoadingPostsMessage({super.key, required this.snapshot});
  final AsyncSnapshot snapshot;
  @override
  Widget build(BuildContext context) {
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
}
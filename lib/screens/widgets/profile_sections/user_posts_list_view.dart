import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/widgets/post_card.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:iconsax/iconsax.dart';

class UserPostsListView extends StatefulWidget {
  final String firebaseUid;
  const UserPostsListView({super.key, required this.firebaseUid});

  @override
  State<UserPostsListView> createState() => _UserPostsListViewState();
}

class _UserPostsListViewState extends State<UserPostsListView> {
  late Future<List<Map<String, dynamic>>> _userPostsFuture;

  @override
  void initState() {
    super.initState();
    _userPostsFuture = ApiService.getUserPosts(widget.firebaseUid);
  }

 

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _userPostsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
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
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
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
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.pen_close2, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        widget.firebaseUid ==
                                auth.FirebaseAuth
                                    .instance.currentUser!.uid
                            ? 'Aún no tienes publicaciones'
                            : 'Este usuario aún no tiene publicaciones',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      widget.firebaseUid ==
                              auth.FirebaseAuth.instance.currentUser!.uid
                          ? Text(
                              '¡Crea tu primera publicación!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).disabledColor,
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
              );
            }
        
            return ListView.separated(
             
              padding: const EdgeInsets.only(top: 6, bottom: 12),
              itemCount: postsData.length,
              separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 4),
              ),
              itemBuilder: (context, index) {
              final postData = postsData[index];
              final int postId = postData['post_id'] ?? postData['id'] ?? 0;
          
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
                      key: ValueKey('post_$postId'),
                      onPostDeleted: _onPostDeleted,
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
    );
    
  }

  // En _UserPostsListViewState, agrega esta función
  void _onPostDeleted(int postId) {
    setState(() {
      // Reconstruir la lista quitando el post eliminado
      _userPostsFuture = _userPostsFuture.then((posts) {
        return posts.where((post) => 
          (post['post_id'] ?? post['id']) != postId
        ).toList();
      });
    });
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    // devolver fecha junto con la hora
    return '${date.day}/${date.month}/${date.year} | ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

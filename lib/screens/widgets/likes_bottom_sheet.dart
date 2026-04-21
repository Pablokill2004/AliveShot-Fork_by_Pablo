import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/pages/pages.dart';
import 'package:alive_shot/services/api_services/api_service.dart';

class LikesBottomSheet {
  static Future<void> showLikesBottomSheet(BuildContext context, int postId) async {
    final colorScheme = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Usuarios que dieron like',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: ApiService.getPostLikingUsers(postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final users = snapshot.data ?? [];
                      if (users.isEmpty) {
                        return const Center(child: Text('No hay usuarios que dieron like'));
                      }

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: users.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final profileImage = user['image'] ?? '';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[200],
                              child: profileImage.isEmpty
                                  ? Icon(
                                      Icons.account_circle,
                                      size: 40,
                                      color: colorScheme.onPrimary,
                                    )
                                  : ClipOval(
                                      child: Image.network(
                                        profileImage,
                                        fit: BoxFit.cover,
                                        width: 40,
                                        height: 40,
                                      ),
                                    ),
                            ),
                            title: Text(user['username'] ?? ''),
                            subtitle: Text('${user['name'] ?? ''} ${user['last_name'] ?? ''}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfilePage(
                                    firebaseUid: user['firebase_uid'],
                                    user: User(
                                      firebaseUid: user['firebase_uid'],
                                      profileImage: user['image'] ?? '',
                                      bannerImage: '',
                                      username: user['username'] ?? '',
                                      fullname: '${user['name'] ?? ''} ${user['last_name'] ?? ''}',
                                      bio: '',
                                      followersCount: 0,
                                      followingCount: 0,
                                      email: '',
                                      name: user['name'] ?? '',
                                      lastname: user['last_name'] ?? '',
                                      birthday: '',
                                      gender: '',
                                      title: '',
                                      address: '',
                                      phone: '',
                                      chlallengesCreated: 0,
                                      challengesWon: 0,
                                      streak: 0,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
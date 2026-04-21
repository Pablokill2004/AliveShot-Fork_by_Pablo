import 'package:flutter/material.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/pages/pages.dart';

class FollowingListPage extends StatefulWidget {
  final String firebaseUid;

  const FollowingListPage({super.key, required this.firebaseUid});

  @override
  State<FollowingListPage> createState() => _FollowingListPageState();
}

class _FollowingListPageState extends State<FollowingListPage> {
  late Future<List<Map<String, dynamic>>> _followingFuture;

  @override
  void initState() {
    super.initState();
    _followingFuture = ApiService.getFollowing(widget.firebaseUid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Siguiendo')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _followingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final following = snapshot.data ?? [];
          if (following.isEmpty) {
            return const Center(child: Text('No sigues a nadie'));
          }
          return ListView.builder(
            itemCount: following.length,
            itemBuilder: (context, index) {
              final followed = following[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(followed['image'] ?? ''),
                ),
                title: Text(followed['username']),
                subtitle: Text('${followed['name']} ${followed['last_name']}'),
                onTap: () {
                  // Navegar al perfil del seguido (usando ProfilePage.route)
                  Navigator.push(
                    context,
                    ProfilePage.route(followed['firebase_uid'], User.fromMap(followed)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
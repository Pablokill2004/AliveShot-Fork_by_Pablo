import 'package:flutter/material.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/pages/pages.dart';

class FollowersListPage extends StatefulWidget {
  final String firebaseUid;

  const FollowersListPage({super.key, required this.firebaseUid});

  @override
  State<FollowersListPage> createState() => _FollowersListPageState();
}

class _FollowersListPageState extends State<FollowersListPage> {
  late Future<List<Map<String, dynamic>>> _followersFuture;

  @override
  void initState() {
    super.initState();
    _followersFuture = ApiService.getFollowers(widget.firebaseUid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguidores')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _followersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final followers = snapshot.data ?? [];
          if (followers.isEmpty) {
            return const Center(child: Text('No tienes seguidores'));
          }
          return ListView.builder(
            itemCount: followers.length,
            itemBuilder: (context, index) {
              final follower = followers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(follower['image'] ?? ''),
                ),
                title: Text(follower['username']),
                subtitle: Text('${follower['name']} ${follower['last_name']}'),
                onTap: () {
                  // Navegar al perfil del seguidor (usando ProfilePage.route)
                  Navigator.push(
                    context,
                    ProfilePage.route(follower['firebase_uid'], User.fromMap(follower)),
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
import 'package:flutter/material.dart';
import 'package:alive_shot/screens/widgets/profile_sections/user_posts_list_view.dart';

class UserPostsTabView extends StatelessWidget {
  final String firebaseUid;
  const UserPostsTabView({super.key, required this.firebaseUid});

  @override
  Widget build(BuildContext context) {
    return UserPostsListView(firebaseUid: firebaseUid);
  }
}
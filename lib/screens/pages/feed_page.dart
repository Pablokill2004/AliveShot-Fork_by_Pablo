import 'package:flutter/material.dart';
import 'package:alive_shot/screens/widgets/widgets.dart';
import '../widgets/feed_page_sections/user_stories_list_view.dart' as user_stories;
import '../widgets/feed_page_sections/posts_list_view.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:alive_shot/screens/models/models.dart';
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  int _postsReloadToken = 0;

  Future<void> _refreshStoriesAndPosts() async {
    try {
      final uid = auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await UserStory.loadFollowingUserStories();
        await ApiService.getUserFeed(uid);
      }
    } catch (e) {
      // ignore errors during refresh
    }
    // After the async work completes, rebuild to pick up new data
    if (mounted) {
      setState(() {
        _postsReloadToken++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: _appBar(theme),
      body: RefreshIndicator(
        color: colorScheme.onPrimary,
        key: _refreshKey,
        onRefresh: _refreshStoriesAndPosts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Sección de Historias (burbujas dinámicas)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: user_stories.UserStoriesListView(),
              ),
            ),
            // Sección de Posts
            SliverToBoxAdapter(
              child: PostsListView(theme: theme, reloadTrigger: _postsReloadToken),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _appBar(ThemeData theme) {
    return AppBar(
      title: AppLogo(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0), // Altura de la línea
        child: Container(
          color: Theme.of(context).dividerColor, // Color de la línea
          height: 1.0, // Grosor de la línea
        ),
      ),
      automaticallyImplyLeading: false,
      flexibleSpace: ResponsivePadding(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              
            ),
          ),
        ),
      ),
    );
  }
}
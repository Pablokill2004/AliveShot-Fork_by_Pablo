import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/widgets/widgets.dart';
import 'package:alive_shot/screens/pages/pages.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:iconsax/iconsax.dart';

import 'package:alive_shot/screens/pages/common_functions/loading_Screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.firebaseUid,
    required this.user,
    this.isNavigatorPushed = false,
  });

  final bool isNavigatorPushed;
  final User user;
  final String firebaseUid;

  @override
  State<ProfilePage> createState() => _ProfilePageState();

  static MaterialPageRoute route(String firebaseUid, User user) {
    return MaterialPageRoute(
      builder: (_) => ProfilePage(
        user: user,
        firebaseUid: firebaseUid,
        isNavigatorPushed: true,
      ),
    );
  }
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  bool _isOptionsVisible = false; // Controla si las opciones están visibles
  late AnimationController _animationController;
  UserStory? currentStory;
  late List<Post> posts;
  bool isLoading = true;

  late Future<Map<String, dynamic>> _userFuture;
  late Future<List<Map<String, dynamic>>> _userPostsFuture;
  int _postsReloadToken = 0;
  int _storyReloadToken = 0;

  @override
  void initState() {
    super.initState();
    posts = Post.dummyPosts.where((e) => e.owner == widget.user).toList();
    _loadUserData();
    _userPostsFuture = ApiService.getUserPosts(widget.firebaseUid);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _userFuture = ApiService.getUser(widget.firebaseUid);
  }

  //Para la animacion del boton de opciones
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshPage() async {
    setState(() {
      _userFuture = ApiService.getUser(widget.firebaseUid);
      _userPostsFuture = ApiService.getUserPosts(widget.firebaseUid);
    });

    // After the async work completes, rebuild to pick up new data
    if (mounted) {
      setState(() {
        _postsReloadToken++;
        _storyReloadToken++;
      });
    }
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: colorScheme.onPrimary,
      onRefresh: _refreshPage,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _appBar(context),
        floatingActionButton: FutureBuilder<Map<String, dynamic>>(
          future: _userFuture,
          builder: (context, snapshot) {
            final isCurrentUser =
                snapshot.data != null &&
                auth.FirebaseAuth.instance.currentUser?.uid ==
                    widget.firebaseUid;
            return isCurrentUser
                ? FloatingActionButton.extended(
                    onPressed: () => PostUploadModal.show(context),
                    backgroundColor: colorScheme.primary,
                    icon: Icon(Iconsax.add, color: colorScheme.onPrimary),
                    label: Text(
                      'Publicar',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.onPrimary,
                    ),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 200),
                    Center(
                      child: Text(
                        'Desliza para reintentar',
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 200),
                    Center(
                      child: Text(
                        'Desliza para reintentar',
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              );
            }
            final user = User.fromMap(snapshot.data!);
            final currentUserUid = auth.FirebaseAuth.instance.currentUser?.uid;
            user.isMe = currentUserUid == widget.firebaseUid;
            return _buildProfileContent(context, user);
          },
        ),
      ),
    );
  }

Widget _buildProfileContent(BuildContext context, User user) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final isMe = user.isMe;
  
 return DefaultTabController(
  length: isMe ? 2 : 1, // Dos pestañas si es el usuario autenticado, una si no
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorScheme.primary,
          colorScheme.secondary,
        ],
      ),
    ),
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            BannerAndProfilePicture(
              context: context,
              userfid: user,
              story: currentStory,
              postsReloadToken: _postsReloadToken,
              userPostsFuture: _userPostsFuture,
              posts: posts,
              storyReloadToken: _storyReloadToken,
              firebaseUid: widget.firebaseUid,
            ),
          ]),
        ),
        SliverFillRemaining(
          hasScrollBody: true,
          child: Column(
            children: [
              UserBio(
                context: context,
                userfid: user,
                postsReloadToken: _postsReloadToken,
                userFuture: _userFuture,
                storyReloadToken: _storyReloadToken,
              ),
              TabBar(
                tabs: isMe
                    ? const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Likes'),
                      ]
                    : const [
                        Tab(text: 'Posts'),
                      ],
                labelColor: textTheme.titleLarge?.color,
                unselectedLabelColor: Theme.of(context).disabledColor,
                indicatorColor: colorScheme.onSecondary,
              ),
              Expanded(
                child: isMe
                    ? TabBarView(
                        children: [
                          UserPostsTabView(firebaseUid: widget.firebaseUid),
                          UserLikedPostsListView(firebaseUid: widget.firebaseUid),
                        ],
                      )
                    : UserPostsTabView(firebaseUid: widget.firebaseUid),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
  
}

  Future<void> _loadUserData() async {
    try {
      final userData = await ApiService.getUser(widget.firebaseUid);
      if (userData.isNotEmpty) {
        final storiesData = await ApiService.getUserStories(widget.firebaseUid);
        final user = User.fromMap(userData);
        final currentUserUid = auth.FirebaseAuth.instance.currentUser?.uid;
        user.isMe = currentUserUid == widget.firebaseUid;
        final userStory = storiesData.isNotEmpty
            ? UserStory.fromMap(userData, storiesData)
            : null;
        setState(() {
          currentStory = userStory;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario no encontrado en la base de datos'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        currentStory = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromARGB(
        0,
        49,
        180,
        90,
      ), //  AppBar transparente
      elevation: 0,
      flexibleSpace: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            widget.isNavigatorPushed
                ? IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  )
                : const SizedBox(),
            Row(
              children: [
                // Opciones extra horizontales
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    child: child,
                  ),
                  child: _isOptionsVisible
                      ? Container(
                          key: const ValueKey(1),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const StoryUploadPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white, // Contraste
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.settings_applications,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(key: ValueKey(2)),
                ),
                // Botón de engranaje que rota
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isOptionsVisible = !_isOptionsVisible;
                      if (_isOptionsVisible) {
                        _animationController.forward();
                      } else {
                        _animationController.reverse();
                      }
                    });
                  },
                  icon: AnimatedRotation(
                    turns: _isOptionsVisible ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      widget.user.isMe ? Icons.settings : Icons.more_horiz,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

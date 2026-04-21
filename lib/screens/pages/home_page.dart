import 'package:firebase_auth/firebase_auth.dart' hide User; //para el
import 'package:flutter/material.dart';
import 'package:alive_shot/screens/common/common.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/pages/pages.dart';
import 'package:alive_shot/screens/models/user.dart';
import 'package:alive_shot/screens/widgets/widgets.dart';
import 'package:alive_shot/services/api_services/api_service.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  final User? user;
  final String? firebaseUid; // Agregar firebaseUid como parámetro opcional

  const HomePage({
    super.key,
    this.initialIndex = 0,
    this.user,
    this.firebaseUid,
  });

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HomePage());
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;
  late PageController _pageController = PageController();

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialIndex; // Usar el índice inicial proporcionado
    _pageController = PageController(initialPage: _pageIndex);
    _loadUnreadCount();

    //actualizar cada vez que se cambie de pagina
    _pageController.addListener(() {
      if (_pageIndex == 2) {
        _loadUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final firebaseUid =
        widget.firebaseUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid == null) return;

    setState(() {});

    try {
      final notifications = await ApiService.getUserNotifications(firebaseUid);
      final unread = notifications.where((n) => !n.isRead).length;

      if (mounted) {
        setState(() {
          _unreadCount = unread;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildNotificationIcon({
    required bool selected,
    required Color? color,
  }) {
    return Stack(
      children: [
        Icon(
          selected ? Icons.notifications : Icons.notifications_outlined,
          color: color,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
              child: _unreadCount > 99
                  ? const Text(
                      '99+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageView = _buildPageView();
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: context.responsive(
        sm: pageView,
        md: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300, // Color del borde
                    width: 1.0, // Grosor del borde
                  ),
                ),
              ),
              child: _navigationRail(context),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Flexible(child: pageView),
          ],
        ),
      ),
      floatingActionButton: _pageIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => PostUploadModal.show(context),
              backgroundColor: colorScheme.primary,
              icon: Icon(Icons.add, color: colorScheme.onPrimary),
              label: Text(
                'Publicar',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      bottomNavigationBar: context.isMobile ? _navigationBar(context) : null,
    );
  }

  void _pageChanged(int value) {
    if (_pageIndex == value && _pageController.hasClients) return;
    setState(() => _pageIndex = value);
    _pageController.jumpToPage(value);
  }

  Widget _buildPageView() {
    _pageController = PageController(initialPage: _pageIndex);

    return PageView(
      controller: _pageController,
      onPageChanged: _pageChanged,
      children: [
        FeedPage(), //), // Página para "Home"
        const SearchPage(), // Temporal para "Search"
        NotificationsPage(
          onNotificationsChanged: _loadUnreadCount,
        ), // Página para "Notifications"
        CompetePage(
          firebaseUid:
              widget.firebaseUid ??
              FirebaseAuth
                  .instance
                  .currentUser!
                  .uid, // Usar el UID proporcionado o el del usuario actual
          user:
              widget.user ??
              User.dummyUsers[0], // Usar el usuario proporcionado o un usuario de prueba
        ), //
        ProfilePage(
          firebaseUid:
              widget.firebaseUid ??
              FirebaseAuth
                  .instance
                  .currentUser!
                  .uid, // Usar el UID proporcionado o el del usuario actual
          user:
              widget.user ??
              User.dummyUsers[0], // Usar el usuario proporcionado o un usuario de prueba
        ), //
      ],
    );
  }

  /// tablet & desktop screen
  NavigationRail _navigationRail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return NavigationRail(
      selectedIndex: _pageIndex,
      onDestinationSelected: _pageChanged,
      extended: context.isDesktop,
      //indicatorColor: colorScheme.onSecondary, // Fondo del ítem seleccionado
      labelType: context.isDesktop
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      selectedLabelTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onPrimary, // Color del texto seleccionado
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: textTheme.bodyMedium?.copyWith(
        color: textTheme.bodyMedium?.color, // Color del texto no seleccionado
      ),
      destinations: [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined, color: textTheme.bodyMedium?.color),
          selectedIcon: Icon(Icons.home, color: colorScheme.onSecondary),
          label: const Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search_outlined, color: textTheme.bodyMedium?.color),
          selectedIcon: Icon(Icons.search, color: colorScheme.onSecondary),
          label: const Text('Search'),
        ),
        NavigationRailDestination(
          icon: _buildNotificationIcon(
            selected: _pageIndex == 2,
            color: textTheme.bodyMedium?.color,
          ),
          selectedIcon: _buildNotificationIcon(
            selected: true,
            color: colorScheme.onSecondary,
          ),
          label: const Text('Notifications'),
        ),
        NavigationRailDestination(
          icon: Icon(
            Icons.interests_outlined,
            color: textTheme.bodyMedium?.color,
          ),
          selectedIcon: Icon(Icons.interests, color: colorScheme.onSecondary),
          label: const Text('To Compete'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outlined, color: textTheme.bodyMedium?.color),
          selectedIcon: Icon(Icons.person, color: colorScheme.onSecondary),
          label: const Text('Profile'),
        ),
      ],
    );
  }

  ///
  NavigationBar _navigationBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return NavigationBar(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      selectedIndex: _pageIndex,
      height: 65,
      onDestinationSelected: _pageChanged,

      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: textTheme.bodyMedium?.color),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined, color: textTheme.bodyMedium?.color),
          selectedIcon: Icon(Icons.search),
          label: 'Search',
        ),
        NavigationDestination(
          icon: _buildNotificationIcon(
            selected: _pageIndex == 2,
            color: textTheme.bodyMedium?.color,
          ),
          selectedIcon: _buildNotificationIcon(
            selected: true,
            color: colorScheme.onSecondary,
          ),
          label: 'Notifications',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.interests_outlined,
            color: textTheme.bodyMedium?.color,
          ),
          selectedIcon: Icon(Icons.interests),
          label: 'To Compete',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outlined, color: textTheme.bodyMedium?.color),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

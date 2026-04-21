import 'dart:async';
import 'package:alive_shot/services/api_services/c_api_services/on_challenge_api_service.dart';
import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:alive_shot/screens/widgets/widgets.dart';
import 'package:flutter_streak/flutter_streak.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:alive_shot/services/api_services/c_api_services/c_api_service.dart';

class CompetePage extends StatefulWidget {
  const CompetePage({super.key, required this.firebaseUid, required this.user});

  final String firebaseUid;
  final User user;

  @override
  State<CompetePage> createState() => _CompetePageState();
  static MaterialPageRoute route(String firebaseUid, User user) {
    return MaterialPageRoute(
      builder: (_) => CompetePage(user: user, firebaseUid: firebaseUid),
    );
  }
}

class _DropdownHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final List<String> sections;
  final String selectedSection;
  final ValueChanged<String?> onChanged;

  _DropdownHeaderDelegate({
    required this.title,
    required this.sections,
    required this.selectedSection,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.onPrimary, width: 1),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: selectedSection,
              onChanged: onChanged,
              dropdownColor: colorScheme.surface,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: colorScheme.onPrimary,
                size: 28,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.secondary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                isCollapsed: true,
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              selectedItemBuilder: (BuildContext context) {
                return sections.map<Widget>((String item) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        _getSectionIcon(item),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: MediaQuery.of(
                                context,
                              ).textScaler.scale(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
              items: sections.map((section) {
                return DropdownMenuItem(
                  value: section,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        _getSectionIcon(section),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            section,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: MediaQuery.of(
                                context,
                              ).textScaler.scale(15),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (selectedSection == section)
                          Icon(
                            Icons.check_circle_rounded,
                            color: colorScheme.secondary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              menuMaxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSectionIcon(String section) {
    switch (section) {
      case 'Disponibles':
        return Icon(
          Icons.explore_rounded,
          color: _getIconColor(section),
          size: 20,
        );
      case 'Retos creados':
        return Icon(
          Icons.person_rounded,
          color: _getIconColor(section),
          size: 20,
        );
      case 'Pendientes':
        return Icon(
          Icons.notifications_rounded,
          color: _getIconColor(section),
          size: 20,
        );
      case 'Participando':
        return Icon(
          Icons.group_rounded,
          color: _getIconColor(section),
          size: 20,
        );
      case 'En juego':
        return Icon(
          Icons.emoji_events_rounded,
          color: _getIconColor(section),
          size: 20,
        );
      default:
        return Icon(
          Icons.category_rounded,
          color: _getIconColor(section),
          size: 20,
        );
    }
  }

  Color _getIconColor(String section) {
    if (section == selectedSection) {
      return Colors.amber;
    }
    return Colors.grey.shade600;
  }

  @override
  double get maxExtent => 130;

  @override
  double get minExtent => 130;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

// Search suggestions builder used by the overlay SearchAnchor

class _CompetePageState extends State<CompetePage>
    with SingleTickerProviderStateMixin {
  bool _isDrawerOpen = false;
  bool _showSearchOverlay = false;
  late bool _isOtherProfile;
  late double rating = 3.0;
  String? _currentUid;
  double _averageRating = 0.0;
  int _ratingCount = 0;
  //late final AnimationController _controller;

  late Future<Map<String, dynamic>> _userData;
  Timer? _timer;
  late String _selectedSection;

  late List<String> _sections;

  // Helper: extract a double from multiple possible keys in a response map
  double _getDoubleFromMap(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) {
        final v = m[k];
        if (v is num) return v.toDouble();
        if (v is String) {
          final cleaned = v.replaceAll(',', '.');
          final parsed = double.tryParse(cleaned);
          if (parsed != null) return parsed;
        }
      }
    }
    return 0.0;
  }

  // Helper: extract an int from multiple possible keys in a response map
  int _getIntFromMap(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) {
        final v = m[k];
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) {
          final cleaned = v.replaceAll(',', '.');
          // try integer first
          final i = int.tryParse(cleaned);
          if (i != null) return i;
          // fallback to parse double then toInt
          final d = double.tryParse(cleaned);
          if (d != null) return d.toInt();
        }
      }
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    // Determine if we are viewing another user's profile. If so, show only
    // a reduced set of sections (Retos creados, Pendientes, Participando).
    final currentUid = auth.FirebaseAuth.instance.currentUser?.uid;
    _currentUid = currentUid;
    _isOtherProfile = currentUid != null && currentUid != widget.firebaseUid;
    if (_isOtherProfile) {
      _sections = ['Retos creados', 'Pendientes', 'Participando'];
      _selectedSection = _sections[0];
    } else {
      _sections = [
        'Disponibles',
        'Retos creados',
        'Pendientes',
        'Participando',
        'En juego',
      ];
      _selectedSection = 'Disponibles';
    }

    _updateStreak();
    _loadUserData();

    _userData = ApiService.getUser(widget.firebaseUid);
    // load aggregate rating
    _loadRating();
  }

  Future<void> _loadRating() async {
    try {
      final ratingData = await CApiService.getUserRating(widget.firebaseUid);
      setState(() {
        // support multiple possible key names returned by the backend
        final avgKeys = [
          'average',
          'average_rating',
          'avg',
          'averageScore',
          'averageRating',
        ];
        final countKeys = [
          'count',
          'total_votes',
          'totalVotes',
          'votes',
          'rating_count',
        ];

        _averageRating = _getDoubleFromMap(
          Map<String, dynamic>.from(ratingData),
          avgKeys,
        );
        _ratingCount = _getIntFromMap(
          Map<String, dynamic>.from(ratingData),
          countKeys,
        );
      });
    } catch (e) {
      // ignore errors for now
    }
  }

  Future<void> _updateStreak() async {
    final uid = widget.firebaseUid;

    // 1) Actualizar en backend
    final backendResult = await ONChallengeApiService.updateStreak(uid);
    final backendStreak = backendResult["streak"];

    // 2) Actualizar flutter_streak
    final localStreak = Streak.i.value.count;

    if (backendStreak > localStreak) {
      await Streak.update();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildContent() {
    switch (_selectedSection) {
      case 'Disponibles':
        return AllChallengesListView(firebaseUid: widget.firebaseUid);
      case 'Retos creados':
        return UserChallengesListView(firebaseUid: widget.firebaseUid);
      case 'Pendientes':
        return RequestedChallengesListView(firebaseUid: widget.firebaseUid);
      case 'Participando':
        return InProgressChallengesListView(firebaseUid: widget.firebaseUid);
      case 'En juego':
        return OngoingChallengesListView(firebaseUid: widget.firebaseUid);
      default:
        return Center(child: Text('Sección no encontrada'));
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await ApiService.getUser(widget.firebaseUid);
      if (userData.isNotEmpty) {
        setState(() {});
      } else {
        setState(() {});
        if (!context.mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario no encontrado en la base de datos'),
            ),
          );
        });
      }
    } catch (e) {
      setState(() {});
      if (!context.mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.onPrimary,
                ),
              ),
            );
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                snapshot.hasError
                    ? 'Error: ${snapshot.error}'
                    : 'Usuario no encontrado',
                style: TextStyle(color: colorScheme.onPrimary),
              ),
            );
          }

          final user = User.fromMap(snapshot.data!);
          //imprimir todos los campos obtenidos de user

          // Main page content wrapped in a Stack so we can overlay the search UI.
          return Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: _profilePicture(
                        context,
                        user,
                        user.profileImage,
                        user.username,
                        user.chlallengesCreated,
                        user.challengesWon,
                        user.streak,
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: _DropdownHeaderDelegate(
                        title: 'Explora retos',
                        sections: _sections,
                        selectedSection: _selectedSection,
                        onChanged: (value) {
                          setState(() {
                            _selectedSection = value!;
                          });
                        },
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: _buildContent(),
              ),

              // Search overlay
              if (_showSearchOverlay)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _showSearchOverlay = false),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                      child: Container(
                        //'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss

                        color: Colors.black.withValues(
                          alpha: 0.4,
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                // Search bar anchored at the top
                                SearchAnchor(
                                  builder:
                                      (
                                        BuildContext context,
                                        SearchController controller,
                                      ) {
                                        return SearchBar(
                                          controller: controller,
                                          hintText: 'Buscar usuarios...',
                                          textStyle: WidgetStateProperty.all(
                                            TextStyle(
                                              color: colorScheme.onPrimary.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontSize: 14,
                                            ),
                                          ),
                                          leading: Icon(Icons.search, color: Theme.of(context).colorScheme.onPrimary),
                                          onTap: () => controller.openView(),
                                          onChanged: (_) =>
                                              controller.openView(),
                                          backgroundColor:
                                              WidgetStateProperty.all(
                                                colorScheme.surfaceContainer
                                                    .withValues(
                                                      alpha: 0.4,
                                                    ),
                                              ),
                                            
                                        );
                                      },
                                  suggestionsBuilder: _searchUsers,
                                ),

                                const SizedBox(height: 12),
                                // Expanded suggestions view will be provided by SearchAnchor
                                Expanded(child: Container()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  FutureOr<Iterable<Widget>> _searchUsers(
    BuildContext context,
    SearchController controller,
  ) async {
    if (controller.text.isEmpty) return const <ListTile>[];
    try {
      final colorScheme = Theme.of(context).colorScheme;
      final results = await ApiService.searchUsers(controller.text);
      return results.map((user) {
        final profileImage = user['image'] ?? '';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 5),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[200],
            child: profileImage == ''
                ? Icon(
                    Icons.account_circle,
                    size: 36,
                    color: colorScheme.onPrimary,
                  )
                : ClipOval(
                    child: Image.network(
                      profileImage,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                    ),
                  ),
          ),
          title: Text(
            user['username'],
            style: TextStyle(color: colorScheme.onPrimary),
          ),
          subtitle: Text(
            '${user['name']} ${user['last_name']}',
            style: TextStyle(color: colorScheme.onPrimary),
          ),
          
          onTap: () {
            controller.closeView(user['username']);
            // Close overlay and open CompetePage for the selected user
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompetePage(
                  firebaseUid: user['firebase_uid'],
                  user: User.fromMap(user),
                ),
              ),
            );
          },
        );
      }).toList();
    } catch (e) {
      return [ListTile(title: Text('Error: $e'))];
    }
  }

  Widget _profilePicture(
    BuildContext context,
    User user,
    String imagenPerfil,
    String userName,
    int retosCreados,
    int retosGanados,
    int fuegoCount,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //imagen de perfil
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image(
                      image: NetworkImage(imagenPerfil),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Información del usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      //mostrar boton de Crear Reto solo si no es otro perfil
                      if (!_isOtherProfile)
                      TextButton(
                        onPressed: () {
                          PostUploadChallengeModal.show(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          backgroundColor: colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.blue, size: 20),
                            SizedBox(width: 4),
                           
                            Text(
                              'Crear Reto',
                              style: TextStyle(
                                fontSize: 16,
                                color: textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      


                      /*TextButton(
                        onPressed: () {
                          PostUploadChallengeModal.show(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          backgroundColor: colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.blue, size: 20),
                            SizedBox(width: 4),
                            // Quitar este boton cuando
                            Text(
                              'Crear Reto',
                              style: TextStyle(
                                fontSize: 16,
                                color: textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),*/

                      const SizedBox(height: 8),
                      Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Retos creados: $retosCreados',
                        style: TextStyle(
                          fontSize: 16,
                          color: textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Retos ganados: $retosGanados',
                            style: TextStyle(
                              fontSize: 16,
                              color: textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$fuegoCount',
                            style: TextStyle(
                              fontSize: 16,
                              color: textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          RatingBar.builder(
                            initialRating: _averageRating > 0
                                ? _averageRating
                                : 0,
                            minRating: 1,
                            itemBuilder: (context, _) =>
                                const Icon(Icons.star, color: Colors.amber),
                            onRatingUpdate: _isOtherProfile
                                ? (value) async {
                                    final doubleStars = value;
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    try {
                                      final res = await CApiService.rateUser(
                                        widget.firebaseUid,
                                        _currentUid ?? '',
                                        doubleStars,
                                      );
                                      setState(() {
                                        final avgKeys = [
                                          'average',
                                          'average_rating',
                                          'avg',
                                          'averageScore',
                                          'averageRating',
                                        ];
                                        final countKeys = [
                                          'count',
                                          'total_votes',
                                          'totalVotes',
                                          'votes',
                                          'rating_count',
                                        ];
                                        _averageRating = _getDoubleFromMap(
                                          Map<String, dynamic>.from(res),
                                          avgKeys,
                                        );
                                        _ratingCount = _getIntFromMap(
                                          Map<String, dynamic>.from(res),
                                          countKeys,
                                        );
                                      });
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Gracias por valorar'),
                                        ),
                                      );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error al enviar valoración: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                : (_) {},
                            itemSize: 19,
                            ignoreGestures: !_isOtherProfile,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_averageRating.toStringAsFixed(1)} ($_ratingCount)',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      // abrir un buscador de usuarios
                      // toggle the overlay search UI
                      _isDrawerOpen = !_isDrawerOpen;
                      _showSearchOverlay = !_showSearchOverlay;
                    });
                  },
                  icon: Icon(
                    _isDrawerOpen ? Icons.close : Icons.search,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            //const Divider(thickness: 1, color: Colors.grey),
            //const SizedBox(height: 12),
            // SizedBox(child: Challenges_list()),
          ],
        ),
      ),
    );
  }
}


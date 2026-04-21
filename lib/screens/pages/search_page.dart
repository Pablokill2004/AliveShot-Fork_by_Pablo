import 'dart:async';
import 'package:alive_shot/screens/models/user.dart';
import 'package:alive_shot/screens/pages/profile_page.dart';
import 'package:alive_shot/screens/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// Flutter code sample for [SearchBar].

void main() => runApp(const SearchPage());

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool isDark = false;

  Widget _buildFollowingButton() {
  return ElevatedButton(
    onPressed: null, // deshabilitado
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[400],
      foregroundColor: Colors.grey[700],
    ),
    child: const Text('Siguiendo'),
  );
}

Widget _buildFollowButton({
  required String currentUserUid,
  required String targetUid,
  required String username,
  required VoidCallback onFollowed,
}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    ),
    onPressed: () async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ApiService.followUser(currentUserUid, targetUid);
        messenger.showSnackBar(
          SnackBar(content: Text('¡Ahora sigues a @$username!')),
        );
        onFollowed(); // recarga la lista
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error al seguir: $e')),
        );
      }
    },
    child: const Text('Seguir', style: TextStyle(fontWeight: FontWeight.bold)),
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme; // Obtén el tema actual
    return Scaffold(
      appBar: AppBar(
        title: AppLogo(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0), // Altura de la línea
          child: Container(
            color: Theme.of(context).dividerColor, // Color de la línea
            height: 1.0, // Grosor de la línea
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.all(10.0),
            padding: const EdgeInsets.all(20.0),
            child: SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                return SearchBar(
                  controller: controller,
                  hintText: 'Buscar usuarios ...',

                  textStyle: WidgetStateProperty.all(
                    Theme.of(context).textTheme.bodyMedium,
                  ),

                  hintStyle: WidgetStateProperty.all(
                    Theme.of(context).textTheme.bodySmall,
                  ),
                  backgroundColor: WidgetStateProperty.all(
                    theme.surfaceContainer,
                  ),
                  padding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  onTap: () {
                    controller.openView();
                  },
                  onChanged: (_) {
                    controller.openView();
                  },
                  leading: Icon(Icons.search, color: theme.onPrimary),
                  /*
                    trailing: <Widget>[
                      Tooltip(
                        message: 'Change brightness mode',
                        child: IconButton(
                          isSelected: isDark,
                          onPressed: () {
                            setState(() {
                              isDark = !isDark;
                            });
                          },
                          icon: const Icon(Icons.wb_sunny_outlined),
                          selectedIcon: const Icon(Icons.brightness_2_outlined),
                        ),
                      ),
                    ],
                    */
                );
              },
              suggestionsBuilder: getUsers,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  FutureOr<Iterable<Widget>> getUsers(
    BuildContext context,
    SearchController controller,
  ) async {
    if (controller.text.isEmpty) {
      return const <ListTile>[];
    }

    try {
      final colorScheme = Theme.of(context).colorScheme;
      final currentUserUid = auth.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserUid == null) return [];

      final results = await ApiService.searchUsers(controller.text);

      // Procesar cada usuario de forma concurrente para verificar si ya lo sigues
      final userWidgets = await Future.wait(
        results.map((userMap) async {
          final userUid = userMap['firebase_uid'] as String;
          final isCurrentUser = currentUserUid == userUid;
          final bool isAlreadyFollowing = isCurrentUser
              ? false
              : await ApiService.isFollowing(currentUserUid, userUid);

          final profileImage = userMap['image'] ?? '';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 5),
            leading: CircleAvatar(
              radius: 22.5,
              backgroundColor: Colors.grey[200],
              child: profileImage.isEmpty
                  ? Icon(Icons.account_circle, size: 45, color: colorScheme.onSurfaceVariant)
                  : ClipOval(
                      child: Image.network(
                        profileImage,
                        fit: BoxFit.cover,
                        width: 45,
                        height: 45,
                      ),
                    ),
            ),
            title: Text(userMap['username'] ?? 'Usuario'),
            subtitle: Text('${userMap['name'] ?? ''} ${userMap['last_name'] ?? ''}'.trim()),
            trailing: isCurrentUser
                ? null
                : (isAlreadyFollowing
                    ? _buildFollowingButton() // Ya lo sigues → botón gris
                    : _buildFollowButton(
                        currentUserUid: currentUserUid,
                        targetUid: userUid,
                        username: userMap['username'] ?? 'usuario',
                        onFollowed: () => setState(() {}), // recarga sugerencias
                      )),

            onTap: () {
              controller.closeView(userMap['username']);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    firebaseUid: userUid,
                    user: User.fromMap(userMap),
                  ),
                ),
              );
            },
          );
        }),
      );

      return userWidgets;
    } catch (e) {
      return [ListTile(title: Text('Error al buscar: $e'))];
    }
  }
}

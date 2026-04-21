import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import 'package:alive_shot/screens/pages/pages.dart';
import 'package:alive_shot/services/api_services/api_service.dart';

class UserBio extends StatefulWidget {
  const UserBio({
    super.key,
    required this.context,
    required this.userfid,
    required this.postsReloadToken,
    required this.userFuture,
    this.storyReloadToken = 0,
  });

  final BuildContext context;
  final User userfid;
  final int postsReloadToken;
  final Future<Map<String, dynamic>> userFuture;
  final int storyReloadToken;

  @override
  State<UserBio> createState() => _UserBioState();
}

class _UserBioState extends State<UserBio> {
  @override
  void didUpdateWidget(covariant UserBio oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger reload when story token changes (e.g., on refresh)
    if (widget.storyReloadToken != oldWidget.storyReloadToken) {
      setState(() {
        future = _loadUserData();
      });
    }
  }

  late Future<void> future = _loadUserData();
  bool isLoading = true;
  UserStory? currentStory;

  Future<void> _loadUserData() async {
    try {
      final userData = await ApiService.getUser(widget.userfid.firebaseUid);
      if (userData.isNotEmpty) {
        final storiesData = await ApiService.getUserStories(
          widget.userfid.firebaseUid,
        );
        final user = User.fromMap(userData);
        final currentUserUid = auth.FirebaseAuth.instance.currentUser?.uid;
        user.isMe = currentUserUid == widget.userfid.firebaseUid;
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder(
      future: future,
      builder: (context, asyncSnapshot) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          child: Column(

            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            widget.userfid.fullname,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textTheme.bodyMedium?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (widget.userfid.isMe)
                          Positioned(
                            right: 0,
                            child: _editprofileButton(
                              context,
                              widget.userfid,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '@${widget.userfid.username}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.userfid.bio.isNotEmpty)
                Center(
                  child: Text(
                    widget.userfid.bio,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                ),
              widget.userfid.isMe
                  ? const SizedBox(height: 16)
                  : _profileButtons(widget.userfid),
            ],
          ),
        );
      },
    );
  }

  Widget _profileButtons(User userfid) {
    final currentUserUid = auth.FirebaseAuth.instance.currentUser?.uid;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: FutureBuilder<bool>(
              future: ApiService.isFollowing(
                currentUserUid ?? '',
                userfid.firebaseUid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 48, 83),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cargando...'),
                  );
                }
                final isFollowing = snapshot.data ?? false;
                // mandar notificacion
                return ElevatedButton(
                  onPressed: currentUserUid != null && !userfid.isMe
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            if (isFollowing) {
                              //Llamar al metodo para dejar de seguir
                              await ApiService.unfollowUser(
                                currentUserUid,
                                userfid.firebaseUid,
                              );
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Dejaste de seguir a @${userfid.username}',
                                  ),
                                ),
                              );
                            } else {
                              //Implementar logica para enviar notificacion al usuario seguido
                              // "A quien voy a seguir" --> followerID: ${widget.firebaseUid}
                              // "User ACTUAL"-->  followingUID: $currentUserUid

                              await ApiService.sendFollowNotification(
                                currentUserUid,
                                userfid.firebaseUid,
                              );
                              await ApiService.followUser(
                                currentUserUid,
                                userfid.firebaseUid,
                              );
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '¡Siguiendo a @${userfid.username}!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing
                        ? Colors.grey[600] // Color invertido para "siguiendo"
                        : const Color.fromARGB(
                            255,
                            0,
                            48,
                            83,
                          ), // Color original para "seguir"
                    foregroundColor: isFollowing ? Colors.white : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isFollowing ? 'Siguiendo' : 'seguir'),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              // redirigir a compete_page de ese usuario
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompetePage(
                      firebaseUid: userfid.firebaseUid,
                      user: userfid,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color.fromARGB(255, 5, 0, 0),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ver en competencia'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editprofileButton(BuildContext context, User userfid) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      icon: const Icon(Icons.edit, size: 12),
      label: Text('Editar'),
      style: OutlinedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 12),
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.onPrimary,
        side: const BorderSide(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 10,
        ), // compacto
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final updatedData = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfilePage(
              initialData: {
                'name': userfid.name,
                'last_name': userfid.lastname,
                'image': userfid.profileImage,
                'image_header': userfid.bannerImage,
                'birthday': userfid.birthday,
                'gender': userfid.gender,
                'title': userfid.title,
                'bio': userfid.bio,
                'address': userfid.address,
                'phone': userfid.phone,
                'username': userfid.username,
              },
            ),
          ),
        );

        if (updatedData != null) {
          try {
            await ApiService.updateUser(userfid.firebaseUid, updatedData);
            setState(() {
              userfid.name = updatedData['name'];
              userfid.lastname = updatedData['last_name'];
              userfid.birthday = updatedData['birthday'];
              userfid.gender = updatedData['gender'];
              userfid.title = updatedData['title'];
              userfid.bio = updatedData['bio'];
              userfid.address = updatedData['address'];
              userfid.phone = updatedData['phone'];
              userfid.username = updatedData['username'];
              userfid.profileImage = updatedData['image'];
              userfid.bannerImage = updatedData['image_header'];
            });
            if (!context.mounted) return;
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Perfil actualizado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text('Error al actualizar el perfil: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}

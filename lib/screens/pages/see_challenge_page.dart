import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:alive_shot/services/api_services/c_api_services/c_api_service.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:intl/intl.dart';
//import 'package:video_player/video_player.dart';
import 'package:alive_shot/screens/widgets/challenges_widgets/challenges_tab_views/join_challenge_modal.dart';
import 'package:alive_shot/screens/pages/compete_page.dart';
import 'package:alive_shot/screens/models/user.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class SeeChallenge extends StatefulWidget {
  final int challengeId;
  final String firebaseUid;

  const SeeChallenge({
    super.key,
    required this.challengeId,
    required this.firebaseUid,
  });

  @override
  State<SeeChallenge> createState() => _SeeChallengeState();
}

class _SeeChallengeState extends State<SeeChallenge> {
  late Future<Map<String, dynamic>> _challengeFuture;
  //VideoPlayerController? _videoController;
  //bool _showControls = true;
  //bool _isPlaying = false;
  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _challengeFuture = CApiService.getChallengeDetail(widget.challengeId);
    _challengeFuture
        .then((challenge) {
          final videoUrl = challenge['content_url'] as String;
          _generateThumbnail(videoUrl);
        })
        .catchError((e) {
          debugPrint('Error al cargar reto: $e');
        });
  }

  /*void _initializeVideo(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _showControls = true;
          });
          // Opcional: reproducir automáticamente
          // _videoController!.play();
          // _isPlaying = true;
        }
      }).catchError((error) {
        debugPrint('Error inicializando video: $error');
      });
  }*/

  @override
  void dispose() {
    super.dispose();
  }

  /*void _togglePlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
        // Ocultar controles después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _videoController!.value.isPlaying) {
            setState(() => _showControls = false);
          }
        });
      }
    });
  }*/

  /*void _toggleControls() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    setState(() => _showControls = !_showControls);
  }*/

  // este widget se utiliza cuando hay una solicitud pendiente
  Widget _buildRequestActions({
    required BuildContext context,
    required String competitorUsername,
    required String competitorProfileImage,
    required String competitorUid,
    required int challengeId,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            try {
              final userData = await ApiService.getUser(competitorUid);
              if (userData.isNotEmpty) {
                if (!mounted) return;
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => CompetePage(
                      firebaseUid: competitorUid,
                      user: User.fromMap(userData),
                    ),
                  ),
                );
              }
            } catch (e) {
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text('Error al cargar perfil: $e')),
              );
            }
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: competitorProfileImage.isNotEmpty
                        ? NetworkImage(competitorProfileImage)
                        : const AssetImage('images/pelicula.png')
                              as ImageProvider,
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@$competitorUsername',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'quiere unirse',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // === BOTONES ACEPTAR / RECHAZAR ===
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptRequest(context, challengeId),
                icon: const Icon(Icons.check, size: 20),
                label: const Text('Aceptar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _rejectRequest(context, challengeId),
                icon: const Icon(Icons.close, size: 20),
                label: const Text('Rechazar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reto'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      drawer: _buildDrawer(colorScheme, textTheme),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _challengeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // AQUI ESTAMOS OBTENIENDO PARAMETROS DEL DESAFIO
          final challenge = snapshot.data!;
          final creatorUid = challenge['creator_uid'] as String;
          final competitorUid = challenge['competitor_user_id'] as String?;
          final isCreator = creatorUid == widget.firebaseUid;
          final isRequester = competitorUid == widget.firebaseUid;
          //final contentUrl = challenge['content_url'] as String;
          final state = challenge['state'] as String;
          // final isWaiting = state == 'waiting';
          final isRequested = state == 'requested';

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colorScheme.primary, Colors.transparent],
                  ),
                ),
              ),

              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //colocar un texto bonito que diga vista previa antes de la imagen
                    Row(
                      children: [
                        Icon(Icons.ondemand_video, color: colorScheme.onPrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Vista Previa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _thumbnail != null
                          ? Image.memory(
                              _thumbnail!,
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),

                    _buildInfoRow(Icons.person, challenge['creator_username']),
                    _buildInfoRow(
                      Icons.calendar_today,
                      _formatDate(challenge['created_at']),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _getStateColor(state),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _getStateColor(state)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStateIcon(state),
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStateText(state),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (isRequested && isRequester)
                      _buildActionButton(
                        label: 'Solicitud Pendiente',
                        icon: Icons.hourglass_top,
                        color: Colors.orange,
                        enabled: false,
                      )
                    else if (isRequested && isCreator && competitorUid != null)
                      _buildRequestActions(
                        context: context,
                        competitorUsername: challenge['competitor_username'],
                        competitorProfileImage:
                            challenge['competitor_profile_image'],
                        competitorUid: competitorUid,
                        challengeId: widget.challengeId,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Drawer ---
  Widget _buildDrawer(ColorScheme colorScheme, TextTheme textTheme) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _challengeFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final challenge = snapshot.data!;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colorScheme.primary, Colors.transparent],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //si challenge tiene creator_profile_pic mostrarla, si no un icono por defecto
                      CircleAvatar(
                        radius: 36,
                        backgroundImage:
                            challenge['creator_profile_image'] != null
                            ? NetworkImage(challenge['creator_profile_image'])
                            : const AssetImage('images/pelicula.png')
                                  as ImageProvider,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        challenge['creator_username'],
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Creador',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                _buildDrawerTile(
                  Icons.category,
                  'Categoría',
                  challenge['category_name'] ?? 'N/A',
                ),
                _buildDrawerTile(
                  Icons.description,
                  'Descripción',
                  challenge['description'] ?? 'Sin descripción',
                ),
                _buildDrawerTile(
                  Icons.calendar_today,
                  'Creado',
                  _formatDate(challenge['created_at']),
                ),
                _buildDrawerTile(
                  Icons.timer,
                  'Estado',
                  _getStateText(challenge['state']),
                ),

                const Divider(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Acciones',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                if (challenge['state'] == 'waiting' &&
                    challenge['creator_uid'] != widget.firebaseUid)
                  ListTile(
                    leading: const Icon(Icons.add_task, color: Colors.green),
                    title: const Text('Solicitar Unirme'),
                    onTap: () {
                      Navigator.pop(context);
                      JoinChallengeModal.show(
                        context,
                        challengeId: widget.challengeId,
                        description: challenge['description'] ?? '',
                      );
                    },
                  )
                else if (challenge['state'] == 'requested')
                  const ListTile(
                    leading: Icon(Icons.hourglass_top, color: Colors.orange),
                    title: Text('Solicitud Pendiente'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: colorScheme.onPrimary),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey.shade300,
          foregroundColor: enabled ? Colors.white : Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: enabled ? 6 : 0,
        ),
      ),
    );
  }

  Future<void> _acceptRequest(BuildContext context, int challengeId) async {
    final messenger = ScaffoldMessenger.of(context); // capturar antes del await
    try {
      await CApiService.acceptRequest(challengeId);
      // eliminar la notificacion de solicitud pendiente de tipo 'challenge_request' se hace en el backend
      await ApiService.deleteChallengeRequestNotification(challengeId);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Solicitud aceptada')),
        );
        setState(() {});
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _generateThumbnail(String videoUrl) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 800,
        quality: 85,
      );
      if (mounted) {
        setState(() {
          _thumbnail = thumbnail;
        });
      }
    } catch (e) {
      debugPrint('Error generando thumbnail: $e');
    }
  }

  Future<void> _rejectRequest(BuildContext context, int challengeId) async {
    final messenger = ScaffoldMessenger.of(context); // capturar antes del await
    try {
      await CApiService.rejectRequest(challengeId);
      await ApiService.deleteChallengeRequestNotification(challengeId);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Solicitud rechazada')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatDate(String date) =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(date));

  Color _getStateColor(String state) => switch (state) {
    'waiting' => Colors.orange,
    'requested' => Colors.yellow.shade700,
    'in_progress' => Colors.blue,
    'completed' => Colors.green,
    _ => Colors.grey,
  };

  IconData _getStateIcon(String state) => switch (state) {
    'waiting' => Icons.access_time,
    'requested' => Icons.hourglass_top,
    'in_progress' => Icons.play_circle,
    'completed' => Icons.check_circle,
    _ => Icons.info,
  };

  String _getStateText(String state) => switch (state) {
    'waiting' => 'Disponible',
    'requested' => 'Solicitado',
    'in_progress' => 'En Curso',
    'completed' => 'Finalizado',
    _ => state,
  };
}

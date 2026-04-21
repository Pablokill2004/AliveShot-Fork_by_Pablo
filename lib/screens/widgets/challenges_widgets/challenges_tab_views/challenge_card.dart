import 'package:flutter/material.dart';
import 'package:alive_shot/screens/pages/pages.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:alive_shot/screens/pages/see_challenge_page.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';
//import asset pelicula.png
//import 'package:alive_shot/others/pelicula.png';

class ChallengeCard extends StatefulWidget {
  final String videoUrl;
  final int views;
  final bool unirmeMode;
  final String state;
  final int? challengeId;
  final String? competitorUid;
  final VoidCallback? onJoin;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTap;
  final String? winnerName;
  final String? winnerRole;

  const ChallengeCard({
    super.key,
    required this.videoUrl,
    required this.views,
    this.unirmeMode = false,
    required this.state,
    this.challengeId,
    this.competitorUid,
    this.onJoin,
    this.onAccept,
    this.onReject,
    this.onTap,
    this.winnerName,
    this.winnerRole,
  });
  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard> {
  Uint8List? _thumbnail;
  String _currentState = "waiting";

  @override
  void initState() {
    super.initState();
    // Normalize state coming from backend (e.g. 'in progress' -> 'in_progress')
    _currentState = widget.state.toString().trim().toLowerCase().replaceAll(
      ' ',
      '_',
    );

    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 55,
      );
      if (mounted) {
        setState(() {
          _thumbnail = thumbnail;
        });
      }
    } catch (e) {
      debugPrint("Error generando miniatura: $e");
    }
  }

  void _handleJoin() {
    if (widget.onJoin != null) {
      widget.onJoin!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap:
          widget.onTap ??
          () {
            if (widget.challengeId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeeChallenge(
                    challengeId: widget.challengeId!,
                    firebaseUid: auth.FirebaseAuth.instance.currentUser!.uid,
                  ),
                ),
              );
            }
          },
      child: Stack(
        children: [
          // Miniatura o placeholder
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black12,
              image: _thumbnail != null
                  ? DecorationImage(
                      image: MemoryImage(_thumbnail!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),

          // Sombras para texto más legible
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black, Colors.transparent],
              ),
            ),
          ),

          // Información en las esquinas
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vistas + Estado arriba a la derecha
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _currentState != "waiting"
                        ? Row(
                            // Muestra las vistas y estados si no es "waiting"
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.views}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                // Present a user-friendly state label
                                // Traducir los estados

                                _currentState
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: _currentState == "requested"
                                      ? Colors.yellowAccent
                                      : _currentState == "in_progress"
                                      ? Colors.blueAccent
                                      : _currentState == "finished"
                                      ? Colors.greenAccent
                                      : Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            //  Muestra el estado SIN las vistas
                            _currentState.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              color: _currentState == "waiting"
                                  ? Colors.orangeAccent
                                  : _currentState == "requested"
                                  ? Colors.yellowAccent
                                  : _currentState == "in_progress"
                                  ? Colors.blueAccent
                                  : _currentState == "finished"
                                  ? Colors.greenAccent
                                  : Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                // Botón “Unirme” o “Aceptar/Rechazar” en la parte inferior
                Align(
                  alignment: Alignment.bottomCenter,
                  child: () {
                    // Caso 1: Mostrar "Unirme" (solo si unirmeMode y estado waiting)
                    if (widget.unirmeMode && _currentState == "waiting") {
                      return ElevatedButton(
                        onPressed: _handleJoin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Solicitar Unirme',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

              
                    // Caso 2: No mostrar nada
                    return const SizedBox.shrink();
                  }(),
                ),
                // Si está terminado y tenemos info del ganador, mostrarla
                if (_currentState == 'finished' && widget.winnerName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'GANADOR: ${widget.winnerName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

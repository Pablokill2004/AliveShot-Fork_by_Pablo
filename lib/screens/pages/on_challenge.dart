import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:alive_shot/screens/pages/compete_page.dart';
import 'package:alive_shot/screens/models/user.dart';
import 'package:intl/intl.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:alive_shot/services/api_services/c_api_services/on_challenge_api_service.dart';
import 'package:alive_shot/screens/widgets/fullscreen_video_viewer.dart';
//importar autenticación de firebase
import 'package:firebase_auth/firebase_auth.dart' as auth;

class OnChallenge extends StatefulWidget {
  final int challengeId;
  final String firebaseUid;

  const OnChallenge({
    super.key,
    required this.challengeId,
    required this.firebaseUid,
  });

  @override
  State<OnChallenge> createState() => _OnChallengeState();
}

class _OnChallengeState extends State<OnChallenge>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _challengeFuture;
  VideoPlayerController? _creatorController;
  VideoPlayerController? _competitorController;

  //variables para el control de los videos
  bool _showCreatorControls = true;
  bool _showCompetitorControls = true;
  bool _isCreatorPlaying = false;
  bool _isCompetitorPlaying = false;
  

  //Conseguir votos a la API
  int _creatorVotes = 0;
  int _competitorVotes = 0;

  late AnimationController _vsAnimationController;
  late Animation<double> _vsPulseAnimation;
  bool _showResultOverlay = true; 

  double _creatorAspectRatio = 9 / 16;
  double _competitorAspectRatio = 9 / 16;
  Timer? _countdownTimer;
  Timer? _statePollingTimer;
  String? _timeRemaining = 'Cargando... ';

  @override
  void initState() {
    super.initState();
    _challengeFuture = ONChallengeApiService.getChallengeInProgress(
      widget.challengeId,
    );
    // Inicializar videos una sola vez cuando la data del future esté disponible
    _challengeFuture
        .then((challenge) {
          if (!mounted) return;
          final state = challenge['state']?.toString() ?? 'in progress';
          if(state == 'finished') {
            setState(() {
              _showResultOverlay = true;
            });
          }

          final joinedAtStr = challenge['joined_at'] as String?;

          // aquí iniciamos el contador si joined_at está presente
          if (joinedAtStr != null) {
            try {
              final joinedAt = DateTime.parse(joinedAtStr);
              _startCountdownTimer(joinedAt);
            } catch (e) {
              debugPrint('Error parsing created_at: $e');
            }
          }

          try {
            _initializeVideos(
              challenge['creator_content_url'] as String?,
              challenge['competitor_content_url'] as String?,
            );
          } catch (e) {
            debugPrint('Error inicializando videos desde future: $e');
          }
        })
        .catchError((e) {
          debugPrint('Error cargando challenge para inicializar videos: $e');
        });
    _loadVotes();
    // Inicializar la animación sin bloquear
    _vsAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _vsPulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _vsAnimationController, curve: Curves.easeInOut),
    );
    _incrementViewOnce();
  }

  Future<void> _incrementViewOnce() async {
    try {
    await ONChallengeApiService.incrementView(
        widget.challengeId,
      );
      // opcional: actualizar UI si muestras el contador en esta pantalla
    } catch (e) {
      // ignorar o debugPrint en desarrollo
    }
  }

  // Nuevo método async separado
  Future<void> _loadVotes() async {
    try {
      final creator = await ONChallengeApiService().getCreatorVotes(
        widget.challengeId,
      );
      final competitor = await ONChallengeApiService().getCompetitorVotes(
        widget.challengeId,
      );

      if (!mounted) return;
      setState(() {
        _creatorVotes = creator;
        _competitorVotes = competitor;
      });
    } catch (e) {
      // opción: log en debug y/o mostrar snackbar si corresponde
      // debugPrint('Error cargando votos: $e');
    }
  }


  // FUNCIÓN PARA INICIAR EL CONTADOR
  void _startCountdownTimer(DateTime joinedAt) {
    _countdownTimer?.cancel();
    _statePollingTimer?.cancel();

    const oneSecond = Duration(seconds: 1);

    _countdownTimer = Timer.periodic(oneSecond, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now().toUtc();

      // AQUÍ SE CAMBIA AL TIEMPO QUE EL PROGRAMADOR DECIDA
      final endTime = joinedAt.add(const Duration(minutes: 5)); // Para pruebas
      //final endTime = createdAt.add(const Duration(hours: 24)).toUtc();
      final difference = endTime.difference(now);

      if (difference.isNegative) {
        setState(() {
          _timeRemaining = 'El reto se está terminando...';
        });
        timer.cancel();
        // Inicia polling agresivo para detectar cambio de estado
        _startStatePolling();
        return;
      }

      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;

      setState(() {
        _timeRemaining = 'Tiempo restante: ${hours}h ${minutes}m ${seconds}s';
      });

      // Inicia polling cuando falten 30 segundos
      if (difference.inSeconds <= 30 && _statePollingTimer == null) {
        _startStatePolling();
      }
    });
  }

  // Polling activo cada 5 segundos para detectar cambio de estado
  void _startStatePolling() {
    _statePollingTimer?.cancel();
    
    _statePollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final challenge = await ONChallengeApiService.getChallengeInProgress(
          widget.challengeId,
        );
        
        if (!mounted) return;

        final state = challenge['state']?.toString() ?? 'in progress';
        
        if (state == 'finished') {
          timer.cancel();
          // Recarga toda la UI para mostrar el overlay de ganador
          setState(() {
            _challengeFuture = Future.value(challenge);
            _showResultOverlay = true;
            _timeRemaining = 'Reto finalizado';
          });
          // Recargar votos finales
          await _loadVotes();
        }
      } catch (e) {
        debugPrint('Error en polling de estado: $e');
      }
    });
  }

  void _initializeVideos(String? creatorUrl, String? competitorUrl) {
    // Dispose any existing controllers first
    _creatorController?.dispose();
    _competitorController?.dispose();
    _creatorController = null;
    _competitorController = null;

    // Helper to create a network controller only for valid http(s) URIs
    VideoPlayerController? createControllerFor(
      String? url,
      void Function() onReady,
    ) {
      if (url == null) return null;
      final uri = Uri.tryParse(url);
      if (uri == null) return null;
      final scheme = uri.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') return null;

      final controller = VideoPlayerController.networkUrl(uri);
      controller.initialize().then((_) {
            if (!mounted) return;

              controller.setVolume(1.0);  
              controller.setLooping(true); // opcional: repetir video

              onReady();
          })
          .catchError((e) {
            // Si la inicialización falla, evitar que la app se rompa.
            debugPrint('Video initialization failed for $url: $e');
          });

      return controller;
    }

    _creatorController = createControllerFor(creatorUrl, () {
      if (!mounted) return;
      setState(() {
        _creatorAspectRatio = _creatorController?.value.aspectRatio ?? (9 / 16);
      });
    });

    _competitorController = createControllerFor(competitorUrl, () {
      if (!mounted) return;
      setState(() {
        _competitorAspectRatio =
            _competitorController?.value.aspectRatio ?? (9 / 16);
      });
    });
  }

  @override
  void dispose() {
    // Primero pausamos (importante para Android)
    _creatorController?.pause();
    _competitorController?.pause();

    // Luego liberamos
    _creatorController?.dispose();
    _competitorController?.dispose();

    _vsAnimationController.dispose();
    _countdownTimer?.cancel();
    _statePollingTimer?.cancel();
    super.dispose();
  }

  void _toggleCreatorPlayPause() {
    if (_creatorController == null ||
        !_creatorController!.value.isInitialized) {
      return;
    }
    setState(() {
      if (_creatorController!.value.isPlaying) {
        _creatorController!.pause();
        _isCreatorPlaying = false;
      } else {
        _creatorController!.play();
        _isCreatorPlaying = true;
        _hideControlsAfterDelay(isCreator: true);
      }
    });
  }

  void _toggleCompetitorPlayPause() {
    if (_competitorController == null ||
        !_competitorController!.value.isInitialized) {
      return;
    }
    setState(() {
      if (_competitorController!.value.isPlaying) {
        _competitorController!.pause();
        _isCompetitorPlaying = false;
      } else {
        _competitorController!.play();
        _isCompetitorPlaying = true;
        _hideControlsAfterDelay(isCreator: false);
      }
    });
  }

  void _hideControlsAfterDelay({required bool isCreator}) {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted &&
          ((isCreator && _isCreatorPlaying) ||
              (!isCreator && _isCompetitorPlaying))) {
        setState(() {
          if (isCreator) {
            _showCreatorControls = false;
          } else {
            _showCompetitorControls = false;
          }
        });
      }
    });
  }

  void _toggleControls({required bool isCreator}) {
    setState(() {
      if (isCreator) {
        _showCreatorControls = !_showCreatorControls;
      } else {
        _showCompetitorControls = !_showCompetitorControls;
      }
    });
  }

  Future<void> _vote(String role) async {
    try {
      final votes = await ONChallengeApiService.sendVote(
        widget.challengeId,
        role,
        createdAt: DateTime.now(),
      );
      // Recargar votos reales desde BD
      await _loadVotes();
      final votesNode = votes['votes'] ?? votes;
      final creatorRaw =
          votesNode['creator_votes'] ?? votesNode['creatorVotes'];
      final joinerRaw = votesNode['joiner_votes'] ?? votesNode['joinerVotes'];

      //username del votado

      final creatorInt =
          int.tryParse(creatorRaw?.toString() ?? '') ?? _creatorVotes;
      final joinerInt =
          int.tryParse(joinerRaw?.toString() ?? '') ?? _competitorVotes;

      setState(() {
        _creatorVotes = creatorInt;
        _competitorVotes = joinerInt;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Voto añadido'),
          backgroundColor: role == 'CREATOR' ? Colors.green : Colors.purple,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar el voto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  //build intentando ser responsive, donde ya involucra videos, usuarios y botones
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _challengeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final challenge = snapshot.data!;
          //print("los datos del challenge son: $challenge");
          final String challengeState = challenge['state']?.toString() ?? 'in progress';
          final bool isFinished = challengeState == 'finished';

          final String? winnerRole = challenge['winner_role']?.toString();

          final bool isCreatorWinner = winnerRole == 'CREATOR';
          final bool isJoinerWinner = winnerRole == 'JOINER';

          final bool isTie = isFinished && winnerRole == 'TIE';
          final bool hasRealWinner = isFinished && winnerRole != null && winnerRole != 'TIE';

          final bool currentUserWon = hasRealWinner && 
              ((winnerRole == 'CREATOR' && challenge['creator_uid'] == widget.firebaseUid) ||
              (winnerRole == 'JOINER' && challenge['competitor_uid'] == widget.firebaseUid));


          //booleano para espectador, es decir, el usuario logueado con auth no es ni creador ni competidor
          final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
          final bool currentUserIsSpectator = 
              currentUser != null &&
              currentUser.uid != challenge['creator_uid'] &&
              currentUser.uid != challenge['competitor_uid'];

          final isParticipant = challenge['creator_uid'] == widget.firebaseUid ||
                              challenge['competitor_uid'] == widget.firebaseUid;
          final isSpectator = !isParticipant;

          // Videos ya se inicializan cuando el Future completa (ver initState)

          final totalVotes = _creatorVotes + _competitorVotes;
          final creatorPercent = totalVotes > 0
              ? _creatorVotes / totalVotes
              : 0.5;
          final competitorPercent = totalVotes > 0
              ? _competitorVotes / totalVotes
              : 0.5;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // === HEADER ===
                          _buildHeader(challenge, colorScheme),

                          // === VS ANIMADO ===
                          AnimatedBuilder(
                            animation: _vsPulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _vsPulseAnimation.value,
                                child: Text(
                                  'VS',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimary,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 16),


                          // === CONTADOR DE TIEMPO ===
                          if (!isFinished)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.access_time, color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _timeRemaining ?? 'Cargando...',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // === BARRA DE VOTOS ===
                          _buildVoteProgressBar(
                            creatorPercent,
                            competitorPercent,
                            colorScheme,
                          ),

                          const SizedBox(height: 24),

                        // === PERFILES DE USUARIOS  ===
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                // CREADOR
                                Expanded(
                                  child: _buildUserProfile(
                                    username: challenge['creator_username'] ?? 'Creador',
                                    profileImage: challenge['creator_profile_image'],
                                    uid: challenge['creator_uid'],
                                    isWinner: isFinished && isCreatorWinner,
                                  ),
                                ),
                                const SizedBox(width: 32), // Espacio para el VS
                                // COMPETIDOR
                                Expanded(
                                  child: _buildUserProfile(
                                    username: challenge['competitor_username'] ?? 'Competidor',
                                    profileImage: challenge['competitor_profile_image'],
                                    uid: challenge['competitor_uid'],
                                    isWinner: isFinished && isJoinerWinner,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // === VIDEOS DE AMBOS PARTICIPANTES ===
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth - 32;
                              final maxWidth = availableWidth / 2;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  children: [
                                    // === CREADOR VIDEO ===
                                    SizedBox(
                                      width: maxWidth,
                                      child: AspectRatio(
                                        aspectRatio: _creatorAspectRatio,
                                        child: _buildCompetitorVideo(
                                          controller: _creatorController,
                                          username: '', // Ya no se usa
                                          profileImage: '', // Ya no se usa
                                          uid: '', // Ya no se usa
                                          votes: _creatorVotes,
                                          showControls: _showCreatorControls,
                                          isPlaying: _isCreatorPlaying,
                                          onTogglePlayPause: _toggleCreatorPlayPause,
                                          onToggleControls: () => _toggleControls(isCreator: true),
                                          isCreator: true,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // === COMPETIDOR VIDEO ===
                                    SizedBox(
                                      width: maxWidth,
                                      child: AspectRatio(
                                        aspectRatio: _competitorAspectRatio,
                                        child: _buildCompetitorVideo(
                                          controller: _competitorController,
                                          username: '',
                                          profileImage: '',
                                          uid: '',
                                          votes: _competitorVotes,
                                          showControls: _showCompetitorControls,
                                          isPlaying: _isCompetitorPlaying,
                                          onTogglePlayPause: _toggleCompetitorPlayPause,
                                          onToggleControls: () => _toggleControls(isCreator: false),
                                          isCreator: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // === BOTONES DE VOTO ===
                          if (isSpectator)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _VoteButton(
                                      label: 'VOTAR',
                                      votes: _creatorVotes,
                                      onPressed: () => _vote('CREATOR'),
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _VoteButton(
                                      label: 'VOTAR',
                                      votes: _competitorVotes,
                                      onPressed: () => _vote('JOINER'),
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 100), // Espacio para FAB
                        ],
                      ),
                    ),
                  ),

                  // === BACK BUTTON ===
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: colorScheme.onPrimary,
                        size: 28,
                      ),
                      onPressed: () async {
                        // Detener ambos videos antes de salir
                        await _creatorController?.pause();
                        await _competitorController?.pause();
                        if (!mounted) return;

                        // Use the State's context (this.context) after the mounted
                        // check to avoid using the builder's context across
                        // async gaps which triggers the analyzer lint.
                        Navigator.of(this.context).pop();
                      },
                    ),
                  ),

                  // === OVERLAY DE GANADOR / PERDEDOR (con botón X para cerrar) ===
                if (isFinished && _showResultOverlay) // <-- Variable de estado que controlamos
                  Positioned.fill(
                    child: Stack(
                      children: [
                        // Fondo oscuro semitransparente
                        GestureDetector(
                          onTap: () => setState(() => _showResultOverlay = false),
                          child: Container(
                            color: Colors.black.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),

                        // Overlay centrado
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 400),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: currentUserWon
                                        ? [Colors.amber.shade700, Colors.orange.shade800]
                                        : [Colors.grey.shade800, Colors.black87],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: currentUserWon ? Colors.amber : Colors.grey.shade600,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentUserWon 
                                          ? Colors.amber.withValues(
                                            alpha:0.6
                                          ) 
                                          : Colors.black.withValues(
                                            alpha: 0.6
                                          ),
                                      blurRadius: 30,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Contenido principal
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Icono según resultado
                                       Icon(
                                          isTie
                                              ? Icons.handshake
                                              : (currentUserIsSpectator
                                                  ? Icons.remove_red_eye
                                                  : (currentUserWon ? Icons.emoji_events : Icons.sentiment_dissatisfied)),
                                          size: 80,
                                          color: isTie
                                              ? Colors.cyanAccent
                                              : (currentUserIsSpectator
                                                  ? Colors.white70
                                                  : (currentUserWon ? Colors.amberAccent : Colors.redAccent)),
                                        ),
                                        const SizedBox(height: 16),

                                        // Título principal
                                        Text(
                                          isTie
                                              ? '¡EMPATE!'
                                              : (currentUserIsSpectator
                                                  ? 'El reto ha terminado'
                                                  : (currentUserWon ? '¡FELICIDADES, HAS GANADO!' : 'LO SIENTO, HAS PERDIDO')),
                                          style: TextStyle(
                                            color: isTie ? Colors.cyan : Colors.white,
                                            fontSize: isTie ? 36 : 28,
                                            fontWeight: FontWeight.bold,
                                            shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),

                                        // Mensaje secundario
                                        Text(
                                          isTie
                                              ? 'Que gran pelea'
                                              : (currentUserIsSpectator
                                                  ? 'Ya no puedes votar en este reto'
                                                  : (currentUserWon
                                                      ? '¡Eres el campeón de este reto!'
                                                      : '¡Mejor suerte la próxima vez!')),
                                          style: TextStyle(
                                            color: isTie ? Colors.cyanAccent : Colors.white70,
                                            fontSize: 18,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),

                                       
                                      ],
                                    ),

                                    // Botón X para cerrar
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _showResultOverlay = false),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.4,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // este lo que hace es construir el header de esta pantalla, es decir, la parte de arriba
  Widget _buildHeader(Map<String, dynamic> challenge, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            challenge['description'] ?? 'Reto sin título',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
              shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                color: colorScheme.onPrimary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Iniciado ${DateFormat('dd MMM yyyy').format(DateTime.parse(challenge['created_at']))}',
                style: TextStyle(color: colorScheme.onPrimary, fontSize: 14),
              ),
              const SizedBox(width: 16),
              
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteProgressBar(
    double creatorPercent,
    double competitorPercent,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            flex: (creatorPercent * 100).toInt(),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            flex: (competitorPercent * 100).toInt(),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Construye el perfil de usuario con imagen, nombre y si es ganador
  Widget _buildUserProfile({
    required String username,
    required String? profileImage,
    required String uid,
    required bool isWinner,
  }) {
    return GestureDetector(
      onTap: () async {
      final messenger = ScaffoldMessenger.of(context);
        try {
          final userData = await ApiService.getUser(uid);
          if (userData.isNotEmpty && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompetePage(
                  firebaseUid: uid,
                  user: User.fromMap(userData),
                ),
              ),
            );
          }
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error al cargar perfil')),
          );
        }
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: profileImage != null && profileImage.isNotEmpty
                    ? NetworkImage(profileImage)
                    : const AssetImage('images/account_circle_placeholder.png') as ImageProvider,
              ),
              if (isWinner)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.amber, blurRadius: 10, spreadRadius: 3),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            username,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  //aquí ya construye el video del competidor, usando el estado de la librería de videoplayer para que el video sea reproducible
  Widget _buildCompetitorVideo({
    required VideoPlayerController? controller,
    required String username,
    required String profileImage,
    required String uid,
    required int votes,
    required bool showControls,
    required bool isPlaying,
    required VoidCallback onTogglePlayPause,
    required VoidCallback onToggleControls,
    required bool isCreator,
  }) {
    return GestureDetector(
      onTap: onToggleControls,
      onLongPress: () {
        // Abrir video en pantalla completa con long press
        if (controller?.value.isInitialized == true) {
          final videoUrl = controller!.dataSource;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullscreenVideoViewer(
                videoUrl: videoUrl,
                isCreator: isCreator,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: controller?.value.isInitialized == true
                    ? FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: controller!.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      )
                    : Container(
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
              ),

              if (showControls && controller?.value.isInitialized == true) ...[
                Center(
                  child: IconButton(
                    iconSize: 56,
                    color: Colors.white,
                    icon: Icon(
                      isPlaying ? Icons.pause_circle : Icons.play_circle,
                      size: 56,
                    ),
                    onPressed: onTogglePlayPause,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: isCreator ? Colors.green : Colors.purple,
                      bufferedColor: Colors.white,
                      backgroundColor: Colors.black,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ],

             // === VOTOS ARRIBA DEL VIDEO (verde/morado) ===
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCreator ? Colors.green.shade600 : Colors.purple.shade600,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(color: Colors.black45, blurRadius: 8),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$votes votos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // Icono de expandir en la esquina superior derecha
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    if (controller?.value.isInitialized == true) {
                      final videoUrl = controller!.dataSource;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullscreenVideoViewer(
                            videoUrl: videoUrl,
                            isCreator: isCreator,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}

//---------------------------------------------------------------------------------------------------

//clase para los botones de votar

class _VoteButton extends StatelessWidget {
  final String label;
  final int votes;
  final VoidCallback onPressed;
  final Color color;

  const _VoteButton({
    required this.label,
    required this.votes,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text('$votes votos', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

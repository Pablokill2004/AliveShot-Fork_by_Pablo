import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:alive_shot/services/api_services/c_api_services/c_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';  // NUEVO: Para Gemini
import 'dart:typed_data';  // NUEVO: Para Uint8List
import 'package:mime/mime.dart';  // NUEVO: Para MIME detection

class JoinChallengeModal extends StatefulWidget {
  final int challengeId;
  final String description;

  const JoinChallengeModal({
    super.key,
    required this.challengeId,
    required this.description,
  });

  static Future<void> show(
    BuildContext context, {
    required int challengeId,
    required String description,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JoinChallengeModal(
        challengeId: challengeId,
        description: description,
      ),
    );
  }

  @override
  State<JoinChallengeModal> createState() => _JoinChallengeModalState();
}

class _JoinChallengeModalState extends State<JoinChallengeModal> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isUploading = false;

  // NUEVO: Variables para IA
  String? _detectedCategory;
  bool _isClassifying = false;
  late final GenerativeModel _geminiModel;

  @override
  void initState() {
    super.initState();
    // NUEVO: Inicialización de Gemini
    _geminiModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.0-flash', 
      generationConfig: GenerationConfig(
        temperature: 0.0,  
        maxOutputTokens: 20,  // suficiente para indicar categoría
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // Método para clasificar video con IA 
  Future<void> _classifyVideo() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_selectedVideo == null || !_selectedVideo!.existsSync()) {
      return;
    }

    setState(() => _isClassifying = true);

    try {
      final fileSize = await _selectedVideo!.length();
      if (fileSize > 500 * 1024 * 1024) {
        throw Exception('El video es demasiado grande (>500MB)');
      }

      final Uint8List videoBytes = await _selectedVideo!.readAsBytes();

      final String mimeType = lookupMimeType(_selectedVideo!.path) ?? 'video/mp4';

      final List<Content> content = [
        Content.text('''
Analiza este video completo (incluyendo audio y video).  
Clasifica la acción principal en SOLO UNA de estas 3 categorías:  
1. EJERCICIO (correr, gym, yoga, baile deportivo, etc.)  
2. BAILE (persona bailando algun tipo de baile)  
3. TOCAR_INSTRUMENTO (guitarra, piano, batería, etc.)  

Responde SOLO con la categoría en mayúsculas y nada más.  
Si no encaja perfectamente en ninguna, responde "OTROS".
'''),
        Content.inlineData(mimeType, videoBytes),
      ];

      final GenerateContentResponse response = await _geminiModel.generateContent(content);

      final String? categoryText = response.text?.trim().toUpperCase();
      final String category = categoryText ?? 'OTROS';

      setState(() => _detectedCategory = category);
      
    } catch (e) {
      setState(() => _detectedCategory = 'ERROR');
      if (context.mounted) {
       messenger.showSnackBar(
          SnackBar(content: Text('Error al clasificar: $e')),
        );
      }
    } finally {
      setState(() => _isClassifying = false);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? file = await _picker.pickVideo(source: source);
      if (file != null && mounted) {
        setState(() {
          _selectedVideo = File(file.path);
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(_selectedVideo!)
            ..initialize()
                .then((_) {
                  if (mounted) setState(() {});
                })
                .catchError((e) {
                  debugPrint('Error inicializando video: $e');
                });
        });
        // NUEVO: Clasificar automáticamente
        _classifyVideo();
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al seleccionar video: $e')),
      );
    }
  }

  Future<void> _uploadAndRequest() async {
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un video')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final firebaseUid = FirebaseAuth.instance.currentUser!.uid;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final storageRef = FirebaseStorage.instance.ref().child(
        'challenge_competitor_videos/$firebaseUid/$fileName',
      );

      final uploadTask = await storageRef.putFile(_selectedVideo!);
      final contentUrl = await uploadTask.ref.getDownloadURL();

      await CApiService.requestToJoin(
        widget.challengeId,
        firebaseUid,
        contentUrl,
        'video',
      );

      if (mounted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return Container(
    height: MediaQuery.of(context).size.height * 0.9,
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Column(
      children: [
        // Handle + Header
        Container(
          width: 40,
          height: 5,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: colorScheme.onSurface),
              ),
              Expanded(
                child: Text(
                  'Unirse al Reto',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_selectedVideo != null &&
                  !_isClassifying &&
                  _detectedCategory != null &&
                  _detectedCategory != 'OTROS')
                TextButton(
                  onPressed: _isUploading ? null : _uploadAndRequest,
                  child: Text(
                    _isUploading ? 'Enviando...' : 'Enviar Solicitud',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Contenido principal
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descripción del reto
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary.withAlpha(75)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Descripción del reto:', style: textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(
                        widget.description.isNotEmpty ? widget.description : 'Sin descripción',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Instrucción + ayuda
                Row(
                  children: [
                    Text(
                      'Graba tu video cumpliendo el reto',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: colorScheme.primary,
                            title: const Text('Categorías permitidas'),
                            content: const Text(
                              'Solo se admiten videos de:\n'
                              '• Baile\n'
                              '• Ejercicio (gym, yoga, correr, etc.)\n'
                              '• Tocar Instrumento (guitarra, piano, batería, etc.)\n\n'
                              'La IA detectará automáticamente una de estas categorías.',
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                            ],
                          ),
                        );
                      },
                      child: Icon(Icons.help_outline, size: 20, color: textTheme.bodyMedium?.color?.withAlpha(179)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Botones de selección (solo si no hay video)
                if (_selectedVideo == null)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSourceButton(
                          icon: Icons.videocam,
                          label: 'Cámara',
                          onTap: () => _pickVideo(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSourceButton(
                          icon: Icons.photo_library,
                          label: 'Galería',
                          onTap: () => _pickVideo(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // === VISTA PREVIA DEL VIDEO (AHORA PERFECTA) ===
                if (_selectedVideo != null) ...[
                  // Estado de IA
                  if (_isClassifying)
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary),
                          SizedBox(height: 12),
                          Text('Analizando tu video...', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (_detectedCategory != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _detectedCategory == 'OTROS'
                              ? 'Video no válido\nSolo se permiten Baile, Ejercicio o Tocar Instrumento'
                              : 'Categoría detectada: $_detectedCategory',
                          style: TextStyle(
                            color: _detectedCategory == 'OTROS' ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Botón quitar
                 

                  const SizedBox(height: 12),

                  // VIDEO PREVIEW CON ASPECT RATIO REAL (como en PostCard)
                  Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 560),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(102),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _videoController != null && _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: _VideoPreview(controller: _videoController!),
                              )
                            : Container(
                                height: 300,
                                color: Colors.black12,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(color: Colors.white),
                                      SizedBox(height: 16),
                                      Text('Cargando vista previa...', style: TextStyle(color: Colors.white70)),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),

                   Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _selectedVideo = null;
                        _videoController?.dispose();
                        _videoController = null;
                        _detectedCategory = null;
                      }),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Quitar', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.grey[700]),
            const SizedBox(height: 8),
            // el color del texto debe ser del esquema de la app por medio de theme.colorScheme.onSurface
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoPreview({required this.controller});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Reproduce en loop y autoplay al cargar
    widget.controller.setLooping(true);
    widget.controller.play();
  }

  @override
  void dispose() {
    widget.controller.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(widget.controller),
          // Overlay de controles
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  colors: [Colors.black45, Colors.transparent],
                ),
              ),
              child: Center(
                child: IconButton(
                  iconSize: 72,
                  color: Colors.white,
                  icon: Icon(
                    widget.controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  ),
                  onPressed: () {
                    setState(() {
                      widget.controller.value.isPlaying
                          ? widget.controller.pause()
                          : widget.controller.play();
                    });
                  },
                ),
              ),
            ),
          ),
          // Barra de progreso
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              widget.controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Theme.of(context).colorScheme.primary,
                bufferedColor: Colors.white54,
                backgroundColor: Colors.black54,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
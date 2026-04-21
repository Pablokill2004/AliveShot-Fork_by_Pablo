import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:video_player/video_player.dart';

class PostUploadModal extends StatefulWidget {
  const PostUploadModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PostUploadModal(),
    );
  }

  @override
  State<PostUploadModal> createState() => _PostUploadModalState();
}

class _PostUploadModalState extends State<PostUploadModal> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  //String? _caption;
  //String? _location;
  String _title = '';
  String _description = '';
  int? _categoryId;
  String? _mediaType;
  bool _isUploading = false;
  VideoPlayerController? _videoController;
  //bool _showControls = true;

  // Categorías de hábitos (RF2.1)
  final List<Map<String, dynamic>> _categories = [
    {'id': 3, 'name': 'Ejercicio', 'icon': Iconsax.heart},
    {'id': 1, 'name': 'Instrumento', 'icon': Iconsax.music},
    {'id': 2, 'name': 'Baile', 'icon': Iconsax.activity},
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header del modal
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colorScheme.onPrimary),
                ),
                Expanded(
                  child: Text(
                    'Crear Publicación',
                    style: TextStyle(
                      color: textTheme.titleLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_selectedFile != null)
                  TextButton(
                    onPressed: _isUploading ? null : _uploadPost,
                    style: TextButton.styleFrom(
                      foregroundColor: _isUploading
                          ? Colors.grey
                          : colorScheme.onPrimary,
                    ),
                    child: Text(_isUploading ? 'Subiendo...' : 'Publicar'),
                  ),
              ],
            ),
          ),

          // Contenido del modal
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  TextField(
                    style: textTheme.bodySmall,
                    decoration: InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: TextStyle(color: colorScheme.onPrimary),

                      hintText: '¿Qué estás compartiendo hoy?',
                      filled: true,
                      fillColor: colorScheme.onSurface.withValues(
                        alpha: 0.1,
                      ),
                    ),

                    maxLength: 200,
                    onChanged: (value) => _title = value,
                    cursorColor: colorScheme.onPrimary,
                  ),

                  const SizedBox(height: 16),

                  // Descripción
                  TextField(
                    style: textTheme.bodySmall,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                       border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle:  TextStyle(color: colorScheme.onPrimary),
                      hintText: 'Cuéntanos más sobre tu actividad...',
                      alignLabelWithHint: true,
                        filled: true,
                      fillColor: colorScheme.onSurface.withValues(
                        alpha: 0.1,
                      ),
                    ),
                    cursorColor: colorScheme.onPrimary,
                    maxLines: 3,
                    onChanged: (value) => _description = value,
                  ),
                  const SizedBox(height: 16),

                  // Selector de categoría
                  Text(
                    'Categoría:',
                    style: TextStyle(
                      color: textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _categoryId == category['id'];

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category['name']),
                            avatar: Icon(
                              category['icon'],
                              size: 16,
                              color: isSelected
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                            ),
                            selected: isSelected,
                            onSelected: isSelected
                                ? null
                                : (selected) => setState(() {
                                    _categoryId = selected
                                        ? category['id']
                                        : null;
                                  }),
                            selectedColor: colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selector de media
                  if (_mediaType == null) ...[
                    // Botones para seleccionar tipo de contenido
                    Row(
                      children: [
                        Expanded(
                          child: _buildSourceButton(
                            icon: Iconsax.image,
                            label: 'Imagen',
                            onTap: () {
                              setState(() => _mediaType = 'image');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSourceButton(
                            icon: Iconsax.video,
                            label: 'Video',
                            onTap: () {
                              setState(() => _mediaType = 'video');
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Selector de origen (cámara/galería)
                    const Text(
                      'Seleccionar desde:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSourceButton(
                            icon: Iconsax.camera,
                            label: 'Cámara',
                            onTap: () => _pickMedia(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSourceButton(
                            icon: Iconsax.gallery,
                            label: 'Galería',
                            onTap: () => _pickMedia(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),

                    // Vista previa del archivo seleccionado
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Vista previa:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 300, // Aumentado para mejor visibilidad
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _mediaType == 'image'
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedFile!,
                                  fit:
                                      BoxFit.contain, // Mostrar imagen completa
                                  errorBuilder: (ctx, _, __) => const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                ),
                              )
                            : _VideoPreview(
                                file: _selectedFile!,
                                controller: _videoController,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            _selectedFile = null;
                            _mediaType = null;
                            _videoController?.dispose();
                            _videoController = null;
                          }),
                          icon: const Icon(Icons.close),
                          label: const Text('Cambiar'),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      XFile? file;
      if (_mediaType == 'image') {
        file = await _picker.pickImage(source: source);
      } else if (_mediaType == 'video') {
        file = await _picker.pickVideo(source: source);
      }

      if (file != null) {
        setState(() {
          _selectedFile = File(file!.path);
          if (_mediaType == 'video') {
            _videoController?.dispose(); // Desechar controlador anterior
            _videoController = VideoPlayerController.file(File(file.path))
              ..initialize()
                  .then((_) {
                    if (mounted) {
                      setState(
                        () {},
                      ); // Actualiza UI cuando el video está listo
                    }
                  })
                  .catchError((error) {
                    debugPrint('Error inicializando video: $error');
                  });
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al seleccionar media: $e')));
    }
  }

  Future<void> _uploadPost() async {
    // Validaciones
    if (_title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El título es requerido')));
      return;
    }

    if (_mediaType != null && _selectedFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una imagen o video')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final firebaseUid = FirebaseAuth.instance.currentUser!.uid;
      String? contentUrl;

      // Subir media a Firebase Storage si se seleccionó
      if (_selectedFile != null && _mediaType != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}.${_mediaType == 'image' ? 'jpg' : 'mp4'}';
        final storageRef = FirebaseStorage.instance.ref().child(
          'posts/$firebaseUid/$fileName',
        );
        final uploadTask = await storageRef.putFile(_selectedFile!);
        contentUrl = await uploadTask.ref.getDownloadURL();
        debugPrint('Media subida a: $contentUrl'); // Debug
      }

      // ✅ CORREGIDO: Llamada al backend sin caption ni location
      await ApiService.createPost(
        firebaseUid,
        _categoryId,
        _title,
        _description.isNotEmpty ? _description : null,
        _mediaType ?? 'text',
        contentUrl,
      );

      // Éxito
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Publicación creada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Cerrar modal
    } catch (e) {
      debugPrint('Error en _uploadPost: $e'); // Debug
      if (!mounted) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear publicación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (context.mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color:Theme.of(context).colorScheme.onPrimary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// Widget temporal para preview de video
class _VideoPreview extends StatefulWidget {
  final File file;
  final VideoPlayerController? controller;

  const _VideoPreview({required this.file, this.controller});

  @override
  _VideoPreviewState createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? VideoPlayerController.file(widget.file)
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {}); // Actualiza UI cuando el video está listo
            }
          })
          .catchError((error) {
            debugPrint('Error inicializando video en preview: $error');
          });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller
          .dispose(); // Solo desechar si no se pasó un controlador externo
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls; // Alternar controles al tocar
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  if (_showControls) ...[
                    // Botón de play/pause
                    IconButton(
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      },
                    ),
                    // Barra de reproducción
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true, // Permite adelantar/retroceder
                        colors: VideoProgressColors(
                          playedColor: Theme.of(context).colorScheme.primary,
                          bufferedColor: Colors.grey,
                          backgroundColor: Colors.black,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        : Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          );
  }
}
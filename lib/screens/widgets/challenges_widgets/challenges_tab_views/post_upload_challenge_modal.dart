import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:video_player/video_player.dart';
import 'package:alive_shot/services/api_services/c_api_services/c_api_service.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'dart:typed_data';
import 'package:mime/mime.dart';

class PostUploadChallengeModal extends StatefulWidget {
  const PostUploadChallengeModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PostUploadChallengeModal(),
    );
  }

  @override
  State<PostUploadChallengeModal> createState() =>
      _PostUploadChallengeModalState();
}

class _PostUploadChallengeModalState extends State<PostUploadChallengeModal> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  // String? _caption;
  //String? _location;
  //String _title = '';
  String _description = '';
  int? _categoryId;
  String? _mediaType;
  bool _isUploading = false;
  VideoPlayerController? _videoController;
  String? _detectedCategory;
  bool _isClassifying = false;
  late final GenerativeModel _geminiModel;


  // Categorías de hábitos (RF2.1)
  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Instrumento', 'icon': Iconsax.music},
    {'id': 2, 'name': 'Baile', 'icon': Iconsax.activity},
    {'id': 3, 'name': 'Ejercicio', 'icon': Iconsax.heart},
    // {'id': 2, 'name': 'Lectura', 'icon': Iconsax.book},
    //{'id': 5, 'name': 'Canto', 'icon': Iconsax.microphone},
    // {'id': 6, 'name': 'Cocina', 'icon': Iconsax.cup},
  ];

  @override
  void initState() {
    super.initState();
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
                    'Crear Reto',
                    style: TextStyle(
                      color: textTheme.titleLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),


                if (_selectedFile != null && 
                    !_isClassifying && 
                    _detectedCategory != null && 
                    _detectedCategory != 'OTROS')
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Descripción
                  TextField(
                    style: textTheme.bodyMedium,
                    cursorColor: textTheme.bodyMedium?.color,
                    decoration: InputDecoration(
                      hintText: 'Descripción',
                      labelText: 'Cuéntanos sobre tu actividad ...',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: colorScheme.onPrimary,
                          width: 2.0,
                        ),
                      ),
                      fillColor: colorScheme.primary, // Color del recuadro
                      filled: true, // Activar el color de fondo
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: textTheme.bodyMedium?.color,
                      ),
                      labelStyle: textTheme.bodyMedium,
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    onChanged: (value) => _description = value,
                  ),
                  const SizedBox(height: 16),


                  Row(
                    children: [
                      Text(
                        'Ayuda',
                        style: TextStyle(
                          color: textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: colorScheme.primary,
                              title: const Text('Categorías permitidas'),
                              content: const Text(
                                'Solo se admiten videos de:\n'
                                '• Baile\n'
                                '• Ejercicio (gym, yoga, correr, etc.)\n'
                                '• Tocar Instrumento (guitarra, piano, batería, etc.)\n\n'
                                'La IA detectará automáticamente una de estas categorías. '
                                'Si no coincide, elige manualmente o sube otro video.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Icon(
                          Icons.help_outline,
                          size: 20,
                          color: textTheme.bodyMedium?.color?.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Selector de media, Imagen o video
                  if (_mediaType == null) ...[
  // Botones para seleccionar tipo de contenido
                    Row(
                      children: [
                        /* Expanded(
                          child: _buildSourceButton(
                            icon: Iconsax.image,
                            label: 'Imagen',
                            onTap: () {
                              setState(() => _mediaType = 'image');
                            },
                          ),
                        ),*/
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
                    // Selector de origen (cámara/galería) - SOLO SI NO HAY ARCHIVO SELECCIONADO
                    if (_selectedFile == null) ...[
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
                    ],

                    // Vista previa del archivo seleccionado
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 16),
                      
                      

                      const SizedBox(height: 8),
                      if (_isClassifying)
                        
                        Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Detectando categoría...',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_detectedCategory != null)
                        Center(
                          child: Column(
                            children: [
                              if (_detectedCategory == 'OTROS')
                                const Text(
                                  'No se detectó ninguna categoría esperada. Intenta de nuevo',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              else
                                Text(
                                  'Categoría detectada: $_detectedCategory',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                      const SizedBox(height: 8),
                      const Text(
                          'Vista previa:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      // vista previa
                      if (_selectedFile != null && _videoController != null && _videoController!.value.isInitialized)
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 500), // límite razonable
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[600]!, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: _VideoPreview(
                                file: _selectedFile!,
                                controller: _videoController,
                              ),
                            ),
                          ),
                        )
                      else if (_selectedFile != null)
                        // Mientras se inicializa el video
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  'Cargando vista previa...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
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
                          //texto del color del esquema
                          label: Text(
                            'Quitar',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      
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

  Future<void> _classifyVideo() async {
    // validamos si el archivo está disponible
    if (_selectedFile == null || !_selectedFile!.existsSync()) {
      return;
    }

    setState(() => _isClassifying = true);
      final messenger = ScaffoldMessenger.of(context);

    try {
      // Verificar tamaño del archivo (opcional - para evitar problemas de memoria)
      final fileSize = await _selectedFile!.length();

      
      if (fileSize > 500 * 1024 * 1024) { // 100MB límite
        throw Exception('El video es demasiado grande (>500MB)');
      }

      // Lee los bytes del video
      final Uint8List videoBytes = await _selectedFile!.readAsBytes();


      // Detecta MIME type (formato del video pues)
      final String mimeType = lookupMimeType(_selectedFile!.path) ?? 'video/mp4';


      // Crea el contenido para Gemini
      final List<Content> content = [
        Content.text('''
  Analiza este video completo (incluyendo audio y video).  
  Clasifica la acción principal en SOLO UNA de estas 3 categorías:  
  1. EJERCICIO (correr, gym, yoga, baile deportivo, etc.)  
  2. BAILE (persona bailando algun tipo de baile)  
  3. INSTRUMENTO (guitarra, piano, batería, etc.)  

  Responde SOLO con la categoría en mayúsculas y nada más.  
  Si no encaja perfectamente en ninguna, responde "OTROS".
  '''),
        Content.inlineData(mimeType, videoBytes),
      ];
      // Genera la respuesta
      //print('Enviando solicitud a Gemini...');
      final GenerateContentResponse response = await _geminiModel.generateContent(content);
      //print('Respuesta recibida: ${response.text}');

      // Extrae la categoría
      final String? categoryText = response.text?.trim().toUpperCase();
      final String category = categoryText ?? 'OTROS';

      setState(() => _detectedCategory = category);
      
      // Actualizar categoría automáticamente si se detectó
      _updateCategoryFromDetection(category);
      
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

  // Función auxiliar para actualizar la categoría automáticamente
  void _updateCategoryFromDetection(String detectedCategory) {
    final categoryMap = {
      'EJERCICIO': 3,
      'BAILE': 2,
      'INSTRUMENTO': 1,
    };

    final categoryId = categoryMap[detectedCategory];
    if (categoryId != null) {
      setState(() {
        _categoryId = categoryId;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoría automática: ${_categories.firstWhere((cat) => cat['id'] == categoryId)['name']}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickMedia(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      XFile? file;
      //if (_mediaType == 'image') {
      //  file = await _picker.pickImage(source: source);
      if (_mediaType == 'video') {
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
          if (_mediaType == 'video' && mounted) {
            //print("Archivo seleccionado: ${_selectedFile!.path}");
            _classifyVideo();
          }

        });
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error al seleccionar media: $e')),
      );
    }
  }

  Future<void> _uploadPost() async {
    // Validaciones
    if (_categoryId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La categoría es requerida')),
      );
      return;
    }

    if (_mediaType != null && _selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un video')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final firebaseUid = FirebaseAuth.instance.currentUser!.uid;
      String? contentUrl;

      // Subir media a Firebase Storage si se seleccionó
      if (_selectedFile != null && _mediaType != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}.${_mediaType = 'mp4'}';
        final storageRef = FirebaseStorage.instance.ref().child(
          'challenge_posts/$firebaseUid/$fileName',
        );
        final uploadTask = await storageRef.putFile(_selectedFile!);
        contentUrl = await uploadTask.ref.getDownloadURL();
        debugPrint('Media subida a: $contentUrl'); // Debug
      }

      // Llamada al backend sin caption ni location
      await CApiService.createChallengePost(
        _categoryId,
        _description.isNotEmpty ? _description : null,
        _mediaType ?? 'text',
        contentUrl,
        firebaseUid,
      );

      // Éxito
      if (context.mounted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Publicación creada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Cerrar modal
      }
    } catch (e) {
      debugPrint('Error en _uploadPost: $e'); // Debug
      if (context.mounted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear publicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    //final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.grey[600]),
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
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _controller.setLooping(true);
        _controller.play();
      }).catchError((e) {
        debugPrint('Error en preview: $e');
      });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(color: Colors.black, child: const Center(child: CircularProgressIndicator()));
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          if (_showControls)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Center(
                child: IconButton(
                  iconSize: 64,
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                    });
                  },
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.cyan,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

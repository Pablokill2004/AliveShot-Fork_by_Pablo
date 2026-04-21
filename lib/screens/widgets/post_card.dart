import 'package:flutter/material.dart';
import 'package:alive_shot/screens/common/common.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/pages/pages.dart';
import 'package:alive_shot/screens/widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
//importar auth de firebase
import 'package:firebase_auth/firebase_auth.dart' as auth;

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.firebaseUid,
    required this.post,
    this.postId,
    this.onPostDeleted,
  });

  final Post post;
  final String firebaseUid;
  final int? postId;
  final void Function(int postId)? onPostDeleted;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with RouteAware{
  //late int _commentCount;
  VideoPlayerController? _videoController;
  bool _showControls = true;
  bool _autoPaused = false;

  

  @override
  void initState() {
    super.initState();
    // _commentCount = widget.post.comments.length;
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    if (widget.post.contentType?.toLowerCase() == 'video') {
      final url = widget.post.postImage;
      final uri = Uri.tryParse(url);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        _videoController = VideoPlayerController.networkUrl(uri)
          ..initialize()
              .then((_) {
                if (mounted) setState(() {});
              })
              .catchError((error) {
                debugPrint('Error inicializando video: $error');
              });
      } else {
        debugPrint('Video URL inválida o vacía: $url');
      }
    }
  }

  /*bool _isVideoUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.avi') ||
        lowerUrl.endsWith('.mkv');
  }*/

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobileCard = _mobileCard(context);
    final tabletCard = _tabletCard(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: context.responsive<Widget>(sm: mobileCard, md: tabletCard),
    );
  }

  Widget _mobileCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
                  // Navegar al perfil del seguido (usando ProfilePage.route)
                  Navigator.push(
                    context,
                    ProfilePage.route(widget.post.owner.firebaseUid, widget.post.owner),
                  );
                },
            leading: CircleAvatar(
              backgroundImage: widget.post.owner.profileImage.isNotEmpty
                  ? NetworkImage(widget.post.owner.profileImage)
                  : const AssetImage('images/pelicula.png') as ImageProvider,
            ),
            title: Text(
              widget.post.owner.username,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Row(
              children: [
                if (widget.post.categoryId != null)
                  Chip(
                    label: Text(_getCategoryName(widget.post.categoryId!)),
                    backgroundColor: colorScheme.surfaceContainer,
                    labelStyle: textTheme.bodySmall,
                  ),
                const SizedBox(width: 8),
              ],
            ),
            // mostrar el boton de opciones solo si el post pertenece al usuario QUE ESTÁ AUTENTICADO
            trailing: widget.post.owner.firebaseUid == auth.FirebaseAuth.instance.currentUser!.uid
              ? PopupMenuButton<String>(
              onSelected: (value) async {
                final message = ScaffoldMessenger.of(context);
                if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Eliminar publicación'),
                      content: const Text('¿Estás seguro de que quieres eliminar esta publicación?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;
                  try {
                    await ApiService.deletePost(widget.postId!);
                    
                    //Notificar al padre que se eliminó
                    widget.onPostDeleted?.call(widget.postId!);

                    if (mounted) {
                      message.showSnackBar(
                        const SnackBar(
                          content: Text('Publicación eliminada'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      message.showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Eliminar Post'),
                ),
              ],
            )
            : null,


            /*trailing: widget.post.owner.firebaseUid == widget.firebaseUid
              ? PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  // Lógica para eliminar el post
                  try {
                    await ApiService.deletePost(widget.postId!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post eliminado correctamente')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al eliminar el post: $e')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Eliminar Post'),
                ),
              ],
            )
            : null,*/

            /*onTap: () => context.push(
              route: ProfilePage.route(
                FirebaseAuth.instance.currentUser!.uid,
                widget.post.owner,
              ),
            ),*/
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.title != null)
                  Text(
                    widget.post.title!,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (widget.post.description != null) const SizedBox(height: 4),
                if (widget.post.description != null)
                  Text(widget.post.description!, style: textTheme.bodyMedium),
                if (widget.post.date != null)
                  Text(
                    '${widget.post.date}',
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: _postImage(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _postButtons(),
          ),
        ],
      ),
    );
  }

  Widget _tabletCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _postImage()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: widget.post.owner.profileImage.isNotEmpty
                          ? NetworkImage(widget.post.owner.profileImage)
                          : const AssetImage('images/pelicula.png')
                                as ImageProvider,
                    ),
                    title: Text(
                      widget.post.owner.username,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        if (widget.post.categoryId != null)
                          Chip(
                            label: Text(
                              _getCategoryName(widget.post.categoryId!),
                            ),
                            backgroundColor: colorScheme.surfaceContainer,
                            labelStyle: textTheme.bodySmall,
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  if (widget.post.title != null)
                    Text(
                      widget.post.title!,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (widget.post.description != null)
                    const SizedBox(height: 4),
                  if (widget.post.description != null)
                    Text(widget.post.description!, style: textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  if (widget.post.date != null)
                    Text(
                      '${widget.post.date}',
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 16),
                  _postButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _postImage() {
    if (widget.post.contentType?.toLowerCase() == 'video') {
    return _videoController != null && _videoController!.value.isInitialized
        ? VisibilityDetector(
            key: ValueKey('video_${widget.postId ?? widget.post.postImage}'), // Clave única por post
            onVisibilityChanged: (VisibilityInfo info) {
              if (info.visibleFraction > 0.5) {
                // Reproduce si fue pausado automáticamente
                if (_autoPaused && _videoController != null) {
                  _videoController!.play();
                  _autoPaused = false;
                }
              } else {
                // Pausa si está reproduciendo
                if (_videoController?.value.isPlaying ?? false) {
                  _videoController!.pause();
                  _autoPaused = true;
                }
              }
            },
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_videoController!),
                    if (_showControls) ...[
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                              _autoPaused = false; // Si pausa manual, no auto-reproduce
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: VideoProgressIndicator(
                          _videoController!,
                          allowScrubbing: true,
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
            ),
          )
        : const AspectRatio(aspectRatio: 16 / 9, child: LoadingImageWidget());
  }

    return Image.network(
      widget.post.postImage,
      fit: BoxFit.fitWidth,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return const AspectRatio(
          aspectRatio: 16 / 9,
          child: LoadingImageWidget(),
        );
      },
      errorBuilder: (ctx, _, __) {
        return const AspectRatio(
          aspectRatio: 16 / 9,
          child: ErrorImageWidget(),
        );
      },
    );
  }

  Widget _postButtons() {
    //colocar ambos botones juntos orillados a la izquierda, ambos con el mismo tamaño
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _ToggleButton(
          isActive: widget.post.isLiked,
          count: widget.post.likeCount,
          iconData: Icons.favorite_outline,
          activeIconData: Icons.favorite,
          postId: widget.postId,
        ),
        const SizedBox(width: 24),
        _CommentButton(post: widget.post, postId: widget.postId),
      ],
    );

    /*return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _ToggleButton(
            isActive: widget.post.isLiked,
            count: widget.post.likeCount,
            iconData: Icons.favorite_outline,
            activeIconData: Icons.favorite,
            postId: widget.postId,
          ),
        ),
        Expanded(
          child: _CommentButton(post: widget.post, postId: widget.postId),
        ),
      ],
    );*/
  }

  String _getCategoryName(int categoryId) {
    const categories = {
      1: 'Instrumento',
      2: 'Baile',
      3: 'Ejercicio',
    };
    return categories[categoryId] ?? 'Otro';
  }
}

class _CommentButton extends StatefulWidget {
  const _CommentButton({required this.post, this.postId});

  final Post post;
  final int? postId;

  @override
  State<_CommentButton> createState() => _CommentButtonState();
}

class _CommentButtonState extends State<_CommentButton> {
  @override
  void didUpdateWidget(_CommentButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Esto se ejecuta cuando el widget se actualiza con nuevos props
    if (oldWidget.post.comments.length != widget.post.comments.length) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PostButton(
      icon: const Icon(Icons.chat_bubble_outline),
      text: widget.post.comments.length.toString(),
      onTap: () =>
          CommentsBottomSheet.showCommentsBottomSheet(
            context,
            post: widget.post,
            postId: widget.postId,
          ).then((_) {
            setState(() {});
          }),
    );
  }
}

class _ToggleButton extends StatefulWidget {
  const _ToggleButton({
    this.count = 122,
    required this.iconData,
    required this.activeIconData,
    required this.isActive,
    // this.onToggle,
    required this.postId,
  });

  final IconData iconData;
  final IconData activeIconData;
  final int count;
  final bool isActive;
  //final VoidCallback? onToggle;
  final int? postId;

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton>
    with AutomaticKeepAliveClientMixin {
  late bool _isActive;
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.count;
    _isActive = widget.isActive;
  }

  @override
  void didUpdateWidget(_ToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.count != widget.count) {
      setState(() {
        _isActive = widget.isActive;
        _count = widget.count;
      });
    }
  }

  Future<void> _toggleLikeOrSave() async {
    final postCard = context.findAncestorWidgetOfExactType<PostCard>();
    if (postCard == null) return;
    final firebaseUid = FirebaseAuth.instance.currentUser!.uid;
    final postId = postCard.postId;

    try {
      if (_isActive) {
        await ApiService.removeLike(firebaseUid, postId!);
        if (mounted) {
          setState(() {
            _isActive = false;
            _count--;
          });
        }
      } else {
        await ApiService.addLike(firebaseUid, postId!);
        if (mounted) {
          setState(() {
            _isActive = true;
            _count++;
          });
        }
      }
      //if (widget.onToggle != null) widget.onToggle!();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al gestionar like: $e')));
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final texto = _count == 1 ? 'like' : 'likes';

    return PostButton(
      icon: Icon(
        _isActive ? widget.activeIconData : widget.iconData,
        color: _isActive ? Colors.red : null,
      ),
      text: '$_count $texto',
      onTap: _toggleLikeOrSave,
      onTextTap: widget.postId != null && _count > 0
          ? () => LikesBottomSheet.showLikesBottomSheet(context, widget.postId!)
          : null, // Abrir modal si hay likes
    );
  }

  @override
  bool get wantKeepAlive => true;
}

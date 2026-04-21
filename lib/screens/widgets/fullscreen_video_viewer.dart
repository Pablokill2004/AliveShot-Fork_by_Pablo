import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullscreenVideoViewer extends StatefulWidget {
  final String videoUrl;
  final bool isCreator;

  const FullscreenVideoViewer({
    super.key,
    required this.videoUrl,
    required this.isCreator,
  });

  @override
  State<FullscreenVideoViewer> createState() => _FullscreenVideoViewerState();
}

class _FullscreenVideoViewerState extends State<FullscreenVideoViewer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(widget.videoUrl);
    _controller = VideoPlayerController.networkUrl(uri);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.setLooping(true);
      _controller.play();
      _isPlaying = true;
      _hideControlsAfterDelay();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
        _hideControlsAfterDelay();
      }
    });
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video en el centro
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),

            // Controles sobre el video
            if (_showControls && _controller.value.isInitialized) ...[
              // Botón de cerrar (X)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Botón de play/pause en el centro
              Center(
                child: IconButton(
                  iconSize: 80,
                  color: Colors.white,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 80,
                  ),
                  onPressed: _togglePlayPause,
                ),
              ),

              // Barra de progreso abajo
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: widget.isCreator
                        ? Colors.green
                        : Colors.purple,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/lyrics_sheet.dart';
import 'queue_sheet.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isDraggingSlider = false;
  double _dragValue = 0.0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    if (AudioManager.instance.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showVolumeDialog(BuildContext context, AudioManager audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(
            color: AppTheme.bgDarkElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Volume",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.volume_mute_rounded, color: AppTheme.textSecondary),
                  Expanded(
                    child: Slider(
                      value: audio.volume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: AppTheme.primaryViolet,
                      onChanged: (val) {
                        setModalState(() {});
                        audio.setVolume(val);
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up_rounded, color: AppTheme.primaryViolet),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showLyricsDialog(BuildContext context, Song song) {
    LyricsSheet.show(context, song);
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioManager.instance;

    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        final song = audio.currentSong;
        if (song == null) {
          return const Scaffold(
            body: Center(child: Text("No song selected")),
          );
        }

        if (audio.isPlaying && !_rotationController.isAnimating) {
          _rotationController.repeat();
        } else if (!audio.isPlaying && _rotationController.isAnimating) {
          _rotationController.stop();
        }

        final isFav = audio.isFavorite(song.id);
        final totalMs = audio.duration.inMilliseconds > 0
            ? audio.duration.inMilliseconds.toDouble()
            : song.duration.inMilliseconds.toDouble();
        final currentMs = _isDraggingSlider
            ? _dragValue
            : audio.position.inMilliseconds.toDouble().clamp(0.0, totalMs);

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  song.artUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: song.gradientColors,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    color: AppTheme.bgDark.withValues(alpha: 0.85),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    // Dynamically scale vinyl disc based on screen height
                    final discSize = (availableHeight * 0.28).clamp(160.0, 260.0);
                    final glowSize = discSize + 10.0;
                    final ring1Size = discSize * 0.85;
                    final ring2Size = discSize * 0.70;
                    final artSize = discSize * 0.48;
                    final centerHoleSize = (discSize * 0.09).clamp(16.0, 24.0);
                    final iconSize = (artSize * 0.32).clamp(24.0, 42.0);

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: availableHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          "PLAYING FROM PLAYLIST",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                            color: AppTheme.textMuted.withValues(alpha: 0.9),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          song.album,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert_rounded),
                                      onPressed: () => _showLyricsDialog(context, song),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(flex: 1),
                              Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: glowSize,
                                      height: glowSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: song.gradientColors.first.withValues(alpha: 0.45),
                                            blurRadius: 40,
                                            spreadRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    RotationTransition(
                                      turns: _rotationController,
                                      child: Container(
                                        width: discSize,
                                        height: discSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF111116),
                                          border: Border.all(color: Colors.white12, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.6),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: ring1Size,
                                              height: ring1Size,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.05),
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: ring2Size,
                                              height: ring2Size,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.05),
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            Hero(
                                              tag: 'album_art_${song.id}',
                                              child: Container(
                                                width: artSize,
                                                height: artSize,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                ),
                                                child: ClipOval(
                                                  child: Image.network(
                                                    song.artUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (ctx, err, stack) => Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(colors: song.gradientColors),
                                                      ),
                                                      child: Icon(
                                                        Icons.music_note,
                                                        color: Colors.white,
                                                        size: iconSize,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: centerHoleSize,
                                              height: centerHoleSize,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppTheme.bgDark,
                                                border: Border.all(color: Colors.white24, width: 2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(flex: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            margin: const EdgeInsets.only(bottom: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.amberAccent.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(
                                                color: Colors.amberAccent.withValues(alpha: 0.5),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.graphic_eq_rounded, color: Colors.amberAccent, size: 10),
                                                SizedBox(width: 4),
                                                Text(
                                                  "STUDIO LOSSLESS FLAC",
                                                  style: TextStyle(
                                                    color: Colors.amberAccent,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            song.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            song.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      iconSize: 28,
                                      icon: Icon(
                                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: isFav ? AppTheme.accentPink : AppTheme.textMuted,
                                      ),
                                      onPressed: () => audio.toggleFavorite(song.id),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                        activeTrackColor: AppTheme.primaryViolet,
                                        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                                        thumbColor: Colors.white,
                                        overlayColor: AppTheme.primaryViolet.withValues(alpha: 0.2),
                                      ),
                                      child: Slider(
                                        min: 0.0,
                                        max: totalMs > 0 ? totalMs : 1.0,
                                        value: currentMs.clamp(0.0, totalMs > 0 ? totalMs : 1.0),
                                        onChangeStart: (val) {
                                          setState(() {
                                            _isDraggingSlider = true;
                                            _dragValue = val;
                                          });
                                        },
                                        onChanged: (val) {
                                          setState(() {
                                            _dragValue = val;
                                          });
                                        },
                                        onChangeEnd: (val) {
                                          _isDraggingSlider = false;
                                          audio.seek(Duration(milliseconds: val.toInt()));
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(Duration(milliseconds: currentMs.toInt())),
                                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                          ),
                                          Text(
                                            _formatDuration(Duration(milliseconds: totalMs.toInt())),
                                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.shuffle_rounded,
                                        color: audio.isShuffle ? AppTheme.primaryViolet : AppTheme.textMuted,
                                        size: 24,
                                      ),
                                      onPressed: () => audio.toggleShuffle(),
                                    ),
                                    IconButton(
                                      iconSize: 36,
                                      icon: const Icon(Icons.skip_previous_rounded),
                                      color: AppTheme.textPrimary,
                                      onPressed: () => audio.previous(),
                                    ),
                                    GestureDetector(
                                      onTap: () => audio.togglePlayPause(),
                                      child: Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: AppTheme.primaryGradient,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primaryViolet.withValues(alpha: 0.45),
                                              blurRadius: 20,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: audio.isBuffering
                                              ? const SizedBox(
                                                  width: 28,
                                                  height: 28,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 3,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Icon(
                                                  audio.isPlaying
                                                      ? Icons.pause_rounded
                                                      : Icons.play_arrow_rounded,
                                                  color: Colors.white,
                                                  size: 38,
                                                ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      iconSize: 36,
                                      icon: const Icon(Icons.skip_next_rounded),
                                      color: AppTheme.textPrimary,
                                      onPressed: () => audio.next(),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.repeat_rounded,
                                        color: audio.isRepeat ? AppTheme.primaryViolet : AppTheme.textMuted,
                                        size: 24,
                                      ),
                                      onPressed: () => audio.toggleRepeat(),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(flex: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.volume_up_rounded, color: AppTheme.textSecondary),
                                      onPressed: () => _showVolumeDialog(context, audio),
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      onPressed: () => _showLyricsDialog(context, song),
                                      icon: const Icon(Icons.subtitles_rounded, size: 16, color: AppTheme.secondaryCyan),
                                      label: const Text(
                                        "LYRICS",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.queue_music_rounded, color: AppTheme.textSecondary),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => const QueueSheet(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

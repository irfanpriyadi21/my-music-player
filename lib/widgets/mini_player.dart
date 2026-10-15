import 'package:flutter/material.dart';
import '../services/audio_manager.dart';
import '../theme/app_theme.dart';
import '../screens/now_playing_screen.dart';
import 'glass_box.dart';
import 'animated_equalizer.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = AudioManager.instance;

    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        final song = audio.currentSong;
        if (song == null) return const SizedBox.shrink();

        final progress = (audio.duration.inMilliseconds > 0)
            ? (audio.position.inMilliseconds / audio.duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, anim, secAnim) => const NowPlayingScreen(),
                  transitionsBuilder: (context, anim, secAnim, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                    return SlideTransition(
                      position: Tween<Offset>(begin: begin, end: end).animate(curve),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: GlassBox(
              blur: 20,
              opacity: 0.85,
              borderRadius: 22,
              color: AppTheme.bgDarkElevated.withValues(alpha: 0.9),
              border: Border.all(
                color: AppTheme.primaryViolet.withValues(alpha: 0.35),
                width: 1.2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'album_art_${song.id}',
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: song.gradientColors.first.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                song.artUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: song.gradientColors),
                                  ),
                                  child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (audio.isPlaying) ...[
                                    const AnimatedEqualizer(isPlaying: true, height: 12, barWidth: 2),
                                    const SizedBox(width: 6),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amberAccent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      "FLAC",
                                      style: TextStyle(
                                        color: Colors.amberAccent,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      song.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          iconSize: 32,
                          icon: audio.isBuffering
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppTheme.primaryViolet,
                                  ),
                                )
                              : Icon(
                                  audio.isPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded,
                                  color: AppTheme.primaryViolet,
                                ),
                          onPressed: () => audio.togglePlayPause(),
                        ),
                        IconButton(
                          iconSize: 26,
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => audio.next(),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 2.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_manager.dart';
import '../theme/app_theme.dart';
import 'animated_equalizer.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback? onTap;

  const SongTile({
    super.key,
    required this.song,
    required this.index,
    this.onTap,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioManager.instance;

    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        final isCurrent = audio.currentSong?.id == song.id;
        final isPlaying = isCurrent && audio.isPlaying;
        final isFav = audio.isFavorite(song.id);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppTheme.primaryViolet.withValues(alpha: 0.12)
                : AppTheme.bgCard.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? AppTheme.primaryViolet.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap ?? () => audio.playSong(song),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Center(
                        child: isPlaying
                            ? const AnimatedEqualizer(isPlaying: true, height: 16)
                            : Text(
                                '${index + 1}'.padLeft(2, '0'),
                                style: TextStyle(
                                  color: isCurrent ? AppTheme.primaryViolet : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: song.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Image.network(
                          song.artUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent ? AppTheme.primaryViolet : AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.amberAccent.withValues(alpha: 0.5),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  "FLAC",
                                  style: TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${song.artist} • ${song.genre}',
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
                    Text(
                      _formatDuration(song.duration),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? AppTheme.accentPink : AppTheme.textMuted,
                        size: 20,
                      ),
                      onPressed: () => audio.toggleFavorite(song.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

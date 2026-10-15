import 'package:flutter/material.dart';
import '../services/audio_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = AudioManager.instance;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.bgDarkElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Playing Queue",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${audio.playlist.length} tracks',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    audio.toggleShuffle();
                  },
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: audio.isShuffle ? AppTheme.primaryViolet : AppTheme.textSecondary,
                    size: 18,
                  ),
                  label: Text(
                    "Shuffle",
                    style: TextStyle(
                      color: audio.isShuffle ? AppTheme.primaryViolet : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: ListenableBuilder(
              listenable: audio,
              builder: (context, _) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: audio.playlist.length,
                  itemBuilder: (context, index) {
                    final song = audio.playlist[index];
                    return SongTile(
                      song: song,
                      index: index,
                      onTap: () {
                        audio.playIndex(index);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import '../services/audio_manager.dart';
import '../services/music_api_service.dart';
import '../theme/app_theme.dart';

class LyricsSheet extends StatefulWidget {
  final Song song;

  const LyricsSheet({
    super.key,
    required this.song,
  });

  static Future<void> show(BuildContext context, Song song) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LyricsSheet(song: song),
    );
  }

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  late Song _song;
  bool _isLoading = false;
  bool _isSyncedMode = true;
  bool _userScrolled = false;
  Timer? _resumeAutoScrollTimer;
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _song = widget.song;
    _isSyncedMode = _song.parsedSyncedLyrics.isNotEmpty;

    if (!_song.hasRealLyrics) {
      _fetchLyrics();
    }
  }

  @override
  void dispose() {
    _resumeAutoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await MusicApiService.instance.fetchLyrics(
        _song.title,
        _song.artist,
        duration: _song.duration,
      );

      if (mounted) {
        if (res != null && res.plainLyrics.isNotEmpty) {
          AudioManager.instance.updateSongLyrics(
            _song.id,
            res.plainLyrics,
            syncedLyrics: res.syncedLyrics,
          );
          setState(() {
            _song = _song.copyWith(
              lyrics: res.plainLyrics,
              syncedLyrics: res.syncedLyrics,
            );
            _isSyncedMode = res.isSynced;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onUserScrollNotification() {
    _userScrolled = true;
    _resumeAutoScrollTimer?.cancel();
    _resumeAutoScrollTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _userScrolled = false;
        });
      }
    });
  }

  void _copyLyrics() {
    final text = _song.lyrics;
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text("Lirik berhasil disalin ke clipboard!"),
          ],
        ),
        backgroundColor: AppTheme.bgDarkElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioManager.instance;
    final currentSong = audio.currentSong;
    final effectiveSong = (currentSong != null && currentSong.id == _song.id) ? currentSong : _song;
    final syncedLines = effectiveSong.parsedSyncedLyrics;
    final hasSynced = syncedLines.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (_, sheetController) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bgDarkElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top drag handle
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "FLAC LYRICS",
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            if (hasSynced)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.mic_none_rounded, size: 10, color: AppTheme.secondaryCyan),
                                    SizedBox(width: 3),
                                    Text(
                                      "SYNCED",
                                      style: TextStyle(
                                        color: AppTheme.secondaryCyan,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          effectiveSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          effectiveSong.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mode selector toggle (Synced vs Plain) if synced is available
                  if (hasSynced)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeTab("Karaoke", _isSyncedMode, () {
                            setState(() => _isSyncedMode = true);
                          }),
                          _buildModeTab("Teks", !_isSyncedMode, () {
                            setState(() => _isSyncedMode = false);
                          }),
                        ],
                      ),
                    ),

                  // Copy button
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    color: AppTheme.textSecondary,
                    tooltip: "Salin Lirik",
                    onPressed: _copyLyrics,
                  ),

                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: AppTheme.textMuted,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 20),

            // Main Content Area
            Expanded(
              child: _buildBody(audio, effectiveSong, syncedLines, sheetController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String title, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    AudioManager audio,
    Song song,
    List<LyricLine> syncedLines,
    ScrollController sheetController,
  ) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryViolet,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Mencari lirik lagu...",
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${song.title} • ${song.artist}",
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (!song.hasRealLyrics && syncedLines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: const Icon(
                  Icons.subtitles_off_rounded,
                  size: 32,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Lirik Belum Tersedia",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Tidak dapat menemukan lirik sinkron maupun teks untuk lagu ini.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: _fetchLyrics,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    // Synced Lyrics Mode
    if (_isSyncedMode && syncedLines.isNotEmpty) {
      return ListenableBuilder(
        listenable: audio,
        builder: (context, _) {
          final currentMs = audio.position.inMilliseconds;
          int activeIndex = -1;
          for (int i = 0; i < syncedLines.length; i++) {
            if (syncedLines[i].time.inMilliseconds <= currentMs) {
              activeIndex = i;
            } else {
              break;
            }
          }

          // Auto-scroll if user hasn't scrolled manually
          if (!_userScrolled && activeIndex != _lastActiveIndex && activeIndex >= 0) {
            _lastActiveIndex = activeIndex;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                final targetOffset = (activeIndex * 58.0 - 140.0).clamp(
                  0.0,
                  _scrollController.position.maxScrollExtent,
                );
                _scrollController.animateTo(
                  targetOffset,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          }

          return Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is UserScrollNotification) {
                    _onUserScrollNotification();
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  itemCount: syncedLines.length,
                  itemBuilder: (context, index) {
                    final line = syncedLines[index];
                    final isActive = index == activeIndex;
                    final isPast = index < activeIndex;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        audio.seek(line.time);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryViolet.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isActive
                              ? Border.all(
                                  color: AppTheme.primaryViolet.withValues(alpha: 0.4),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Text(
                          line.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isActive ? 20 : 16,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            height: 1.5,
                            color: isActive
                                ? Colors.white
                                : (isPast
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.7)),
                            shadows: isActive
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryViolet.withValues(alpha: 0.8),
                                      blurRadius: 15,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // "Resume Sync" pill button if user has scrolled away
              if (_userScrolled && activeIndex >= 0)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _userScrolled = false;
                        });
                        if (_scrollController.hasClients) {
                          final targetOffset = (activeIndex * 58.0 - 140.0).clamp(
                            0.0,
                            _scrollController.position.maxScrollExtent,
                          );
                          _scrollController.animateTo(
                            targetOffset,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              "Ikuti Lirik",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    // Plain Lyrics Mode
    return ListView(
      controller: sheetController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      children: [
        Text(
          song.lyrics,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            height: 1.9,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_manager.dart';
import '../services/music_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedGenre = "Trending";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<Song> _currentGenreSongs = [];
  List<Song> _searchedSongs = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  final List<String> _genres = [
    "Trending",
    "Pop",
    "Rock",
    "Hip Hop",
    "R&B",
    "Lo-Fi",
    "Electronic",
    "Indie",
    "Jazz",
    "Acoustic",
    "Indonesia",
    "Favorites",
  ];

  @override
  void initState() {
    super.initState();
    _loadGenreTracks(_selectedGenre);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadGenreTracks(String genre, {bool forceRefresh = false}) async {
    if (genre == "Favorites") {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tracks = (genre == "Trending")
          ? await MusicApiService.instance.fetchTrendingTracks(forceRefresh: forceRefresh)
          : await MusicApiService.instance.fetchGenreTracks(genre);

      if (mounted) {
        setState(() {
          _currentGenreSongs = tracks.isNotEmpty ? tracks : Song.sampleSongs;
          _isLoading = false;
        });

        // Set playlist in audio manager if currently empty
        final audio = AudioManager.instance;
        if (audio.playlist.isEmpty) {
          audio.setPlaylist(_currentGenreSongs, startIndex: 0, autoPlay: false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentGenreSongs = Song.sampleSongs;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
    });

    _searchDebounce?.cancel();
    if (val.trim().length >= 2) {
      _searchDebounce = Timer(const Duration(milliseconds: 450), () async {
        if (!mounted) return;
        setState(() {
          _isSearching = true;
        });

        final results = await MusicApiService.instance.searchTracks(val.trim());
        if (mounted) {
          setState(() {
            _searchedSongs = results;
            _isSearching = false;
          });
        }
      });
    } else {
      setState(() {
        _searchedSongs = [];
        _isSearching = false;
      });
    }
  }

  List<Song> _getDisplayedSongs(AudioManager audio) {
    if (_searchQuery.trim().isNotEmpty) {
      if (_searchedSongs.isNotEmpty) {
        return _searchedSongs;
      }
      final q = _searchQuery.toLowerCase();
      return _currentGenreSongs.where((s) =>
          s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q)).toList();
    }

    if (_selectedGenre == "Favorites") {
      final all = <Song>[..._currentGenreSongs, ...Song.sampleSongs];
      return all.where((s) => audio.isFavorite(s.id)).toList();
    }

    return _currentGenreSongs.isNotEmpty ? _currentGenreSongs : Song.sampleSongs;
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioManager.instance;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              color: Colors.amberAccent,
              backgroundColor: AppTheme.bgDarkElevated,
              onRefresh: () => _loadGenreTracks(_selectedGenre, forceRefresh: true),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // App Bar / Greeting
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.amberAccent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amberAccent,
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "MONOCHROME • LOSSLESS FLAC",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: Colors.amberAccent.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Hi-Res Music Player",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                                tooltip: "Refresh FLAC Tracks",
                                onPressed: () => _loadGenreTracks(_selectedGenre, forceRefresh: true),
                              ),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amberAccent.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.album_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Search songs, artists, albums (Monochrome FLAC)...",
                            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            prefixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged("");
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Genre Filter Chips
                  if (_searchQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: _genres.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final genre = _genres[index];
                            final isSelected = _selectedGenre == genre;

                            return ChoiceChip(
                              avatar: genre == "Favorites"
                                  ? Icon(
                                      Icons.favorite_rounded,
                                      size: 14,
                                      color: isSelected ? Colors.white : AppTheme.accentPink,
                                    )
                                  : null,
                              label: Text(
                                genre,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedGenre = genre;
                                  });
                                  _loadGenreTracks(genre);
                                }
                              },
                              selectedColor: Colors.amber.shade700,
                              backgroundColor: AppTheme.bgCard,
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.amberAccent
                                    : Colors.white.withValues(alpha: 0.06),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              showCheckmark: false,
                            );
                          },
                        ),
                      ),
                    ),

                  // Featured Horizontal Carousel
                  if (_searchQuery.isEmpty && _selectedGenre != "Favorites") ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Featured in $_selectedGenre",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "FLAC",
                                    style: TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ListenableBuilder(
                              listenable: audio,
                              builder: (context, _) {
                                final displayed = _getDisplayedSongs(audio);
                                return TextButton(
                                  onPressed: displayed.isNotEmpty
                                      ? () => audio.setPlaylist(displayed, startIndex: 0, autoPlay: true)
                                      : null,
                                  child: const Text(
                                    "Play All",
                                    style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ListenableBuilder(
                        listenable: audio,
                        builder: (context, _) {
                          final featured = _getDisplayedSongs(audio).take(10).toList();
                          if (featured.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return SizedBox(
                            height: 200,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: featured.length,
                              itemBuilder: (context, index) {
                                final song = featured[index];
                                return GestureDetector(
                                  onTap: () => audio.playSong(song, contextPlaylist: featured),
                                  child: Container(
                                    width: 155,
                                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: song.gradientColors,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: song.gradientColors.first.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.network(
                                            song.artUrl,
                                            width: 155,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            color: Colors.black.withValues(alpha: 0.35),
                                            colorBlendMode: BlendMode.darken,
                                            errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                                          ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withValues(alpha: 0.25),
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          left: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'FLAC',
                                              style: TextStyle(
                                                color: Colors.amberAccent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 12,
                                          left: 12,
                                          right: 12,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                song.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                song.artist,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // List Header (Section Name & Track Count)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _searchQuery.isNotEmpty
                                ? "Search Results"
                                : (_selectedGenre == "Favorites"
                                    ? "Favorite Tracks"
                                    : "$_selectedGenre Tracks"),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          ListenableBuilder(
                            listenable: audio,
                            builder: (context, _) {
                              final count = _getDisplayedSongs(audio).length;
                              return Text(
                                '$count FLAC tracks',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Loading Indicator
                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: Colors.amberAccent),
                              SizedBox(height: 16),
                              Text(
                                "Loading Lossless FLAC tracks from Monochrome...",
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_errorMessage != null && _currentGenreSongs.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_off_rounded, color: AppTheme.textMuted, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                "Connection issue: $_errorMessage",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _loadGenreTracks(_selectedGenre, forceRefresh: true),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text("Retry Monochrome"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // Main Song List
                    ListenableBuilder(
                      listenable: audio,
                      builder: (context, _) {
                        final displayed = _getDisplayedSongs(audio);

                        if (displayed.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.music_off_rounded, color: AppTheme.textMuted, size: 48),
                                    SizedBox(height: 12),
                                    Text(
                                      "No songs found",
                                      style: TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = displayed[index];
                              return SongTile(
                                song: song,
                                index: index,
                                onTap: () => audio.playSong(song, contextPlaylist: displayed),
                              );
                            },
                            childCount: displayed.length,
                          ),
                        );
                      },
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),

            // Persistent Floating MiniPlayer
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }
}

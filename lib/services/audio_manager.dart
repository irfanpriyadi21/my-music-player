import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/song.dart';
import 'music_api_service.dart';

class AudioManager extends ChangeNotifier {
  static final AudioManager instance = AudioManager._internal();
  AudioManager._internal() {
    _initAudioPlayer();
  }

  factory AudioManager() => instance;

  final AudioPlayer _player = AudioPlayer();

  final List<Song> _playlist = List.from(Song.sampleSongs);
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffle = false;
  bool _isRepeat = false;
  double _volume = 1.0;
  final Set<String> _favoriteSongIds = {'1', '3'};

  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Song? get currentSong => _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  double get volume => _volume;
  Set<String> get favoriteSongIds => _favoriteSongIds;

  void _initAudioPlayer() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      _isBuffering = false;
      notifyListeners();
    });

    _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      if (_isRepeat) {
        seek(Duration.zero);
        _player.resume();
      } else {
        next();
      }
    });
  }

  Future<void> fetchLyricsForCurrentSong() async {
    final song = currentSong;
    if (song == null) return;
    if (song.hasRealLyrics) return;

    final targetId = song.id;
    try {
      final res = await MusicApiService.instance.fetchLyrics(
        song.title,
        song.artist,
        duration: song.duration,
      );
      if (res != null && res.plainLyrics.isNotEmpty) {
        updateSongLyrics(targetId, res.plainLyrics, syncedLyrics: res.syncedLyrics);
      }
    } catch (e) {
      debugPrint("Error fetching lyrics for current song: $e");
    }
  }

  void updateSongLyrics(String songId, String plainLyrics, {String? syncedLyrics}) {
    for (int i = 0; i < _playlist.length; i++) {
      if (_playlist[i].id == songId) {
        _playlist[i] = _playlist[i].copyWith(
          lyrics: plainLyrics,
          syncedLyrics: syncedLyrics,
        );
        notifyListeners();
        break;
      }
    }
  }

  Future<void> playIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    final song = _playlist[_currentIndex];
    _position = Duration.zero;
    _duration = song.duration;
    _isBuffering = true;
    notifyListeners();

    // Fetch lyrics in background if not loaded yet
    fetchLyricsForCurrentSong();

    try {
      await _player.stop();
      await _player.play(UrlSource(song.url));
      _isPlaying = true;
      _isBuffering = false;
    } catch (e) {
      _isBuffering = false;
      _isPlaying = false;
      debugPrint("Error playing audio: $e");
    }
    notifyListeners();
  }

  Future<void> setPlaylist(List<Song> songs, {int startIndex = 0, bool autoPlay = true}) async {
    if (songs.isEmpty) return;
    _playlist
      ..clear()
      ..addAll(songs);
    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    if (autoPlay) {
      await playIndex(_currentIndex);
    } else {
      final song = _playlist[_currentIndex];
      _position = Duration.zero;
      _duration = song.duration;
      notifyListeners();
    }
  }

  Future<void> playSong(Song song, {List<Song>? contextPlaylist}) async {
    if (contextPlaylist != null && contextPlaylist.isNotEmpty) {
      _playlist
        ..clear()
        ..addAll(contextPlaylist);
      final index = _playlist.indexWhere((s) => s.id == song.id);
      await playIndex(index != -1 ? index : 0);
      return;
    }

    final index = _playlist.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      await playIndex(index);
    } else {
      _playlist.insert(_currentIndex + 1 < _playlist.length ? _currentIndex + 1 : _playlist.length, song);
      await playIndex(_currentIndex + 1 < _playlist.length ? _currentIndex + 1 : _playlist.length - 1);
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.state == PlayerState.paused) {
        await _player.resume();
      } else {
        await playIndex(_currentIndex);
      }
    }
    notifyListeners();
  }

  Future<void> seek(Duration newPosition) async {
    _position = newPosition;
    await _player.seek(newPosition);
    notifyListeners();
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    if (_isShuffle) {
      final random = Random();
      int newIndex;
      do {
        newIndex = random.nextInt(_playlist.length);
      } while (newIndex == _currentIndex && _playlist.length > 1);
      await playIndex(newIndex);
    } else {
      int nextIdx = _currentIndex + 1;
      if (nextIdx >= _playlist.length) {
        nextIdx = 0;
      }
      await playIndex(nextIdx);
    }
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    int prevIdx = _currentIndex - 1;
    if (prevIdx < 0) {
      prevIdx = _playlist.length - 1;
    }
    await playIndex(prevIdx);
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  void toggleFavorite(String songId) {
    if (_favoriteSongIds.contains(songId)) {
      _favoriteSongIds.remove(songId);
    } else {
      _favoriteSongIds.add(songId);
    }
    notifyListeners();
  }

  bool isFavorite(String songId) {
    return _favoriteSongIds.contains(songId);
  }

  void reorderPlaylist(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, item);
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
      _currentIndex -= 1;
    } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
      _currentIndex += 1;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

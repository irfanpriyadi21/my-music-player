import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class MusicApiService {
  static final MusicApiService instance = MusicApiService._internal();
  MusicApiService._internal();
  factory MusicApiService() => instance;

  static const String _browserUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

  final Map<String, List<Song>> _genreCache = {};
  List<Song> _trendingTracks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Song> get trendingTracks => _trendingTracks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const List<String> availableGenres = [
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
  ];

  Future<List<Song>> fetchTrendingTracks({bool forceRefresh = false, int limit = 35}) async {
    if (_trendingTracks.isNotEmpty && !forceRefresh) {
      return _trendingTracks;
    }

    _isLoading = true;
    _errorMessage = null;

    try {
      final tracks = await fetchGenreTracks("popular", limit: limit);
      if (tracks.isNotEmpty) {
        _trendingTracks = tracks;
      }
      _isLoading = false;
      return _trendingTracks;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      debugPrint("MusicApiService fetchTrendingTracks error: $e");
      return _trendingTracks;
    }
  }

  Future<List<Song>> fetchGenreTracks(String genre, {int limit = 30}) async {
    final key = genre.toLowerCase();
    if (_genreCache.containsKey(key) && _genreCache[key]!.isNotEmpty) {
      return _genreCache[key]!;
    }

    try {
      final query = (key == "trending" || key == "all") ? "popular" : key;
      final encoded = Uri.encodeQueryComponent(query);
      final response = await http.get(
        Uri.parse('https://tracks.monochrome.st/search/tracks?q=$encoded&limit=$limit'),
        headers: {
          'User-Agent': _browserUserAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['tracks'] is List) {
          final List list = body['tracks'];
          final List<Song> parsed = [];
          for (final item in list) {
            try {
              if (item is Map<String, dynamic> && item['playable'] != false) {
                parsed.add(Song.fromMonochromeJson(item, category: genre.toUpperCase()));
              }
            } catch (e) {
              // Ignore single item error
            }
          }
          if (parsed.isNotEmpty) {
            _genreCache[key] = parsed;
          }
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('MusicApiService fetchGenreTracks ($genre) error: $e');
    }
    return _genreCache[key] ?? [];
  }

  Future<List<Song>> searchTracks(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];

    try {
      final encoded = Uri.encodeQueryComponent(query.trim());
      final response = await http.get(
        Uri.parse('https://tracks.monochrome.st/search/tracks?q=$encoded&limit=$limit'),
        headers: {
          'User-Agent': _browserUserAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['tracks'] is List) {
          final List list = body['tracks'];
          final List<Song> parsed = [];
          for (final item in list) {
            try {
              if (item is Map<String, dynamic> && item['playable'] != false) {
                parsed.add(Song.fromMonochromeJson(item));
              }
            } catch (e) {
              // Ignore
            }
          }
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('MusicApiService searchTracks ($query) error: $e');
    }
    return [];
  }

  final Map<String, LyricsResult> _lyricsCache = {};

  String _sanitizeTitle(String title) {
    var cleaned = title;
    cleaned = cleaned.replaceAll(RegExp(r'\s*[\(\[](feat|ft|with|prod)\.?.*?[\]\)]', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*[\(\[](remastered|remaster|live|radio edit|deluxe|version).*?[\]\)]', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*(remastered|live|radio edit).*', caseSensitive: false), '');
    return cleaned.trim();
  }

  String _sanitizeArtist(String artist) {
    var cleaned = artist;
    if (cleaned.contains(',')) {
      cleaned = cleaned.split(',').first;
    }
    if (cleaned.contains('&')) {
      cleaned = cleaned.split('&').first;
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s*(feat|ft)\.?.*', caseSensitive: false), '');
    return cleaned.trim();
  }

  Future<LyricsResult?> fetchLyrics(String title, String artist, {Duration? duration}) async {
    final cleanTitle = _sanitizeTitle(title);
    final cleanArtist = _sanitizeArtist(artist);
    if (cleanTitle.isEmpty || cleanArtist.isEmpty) return null;

    final cacheKey = '${cleanTitle.toLowerCase()}|${cleanArtist.toLowerCase()}';
    if (_lyricsCache.containsKey(cacheKey)) {
      return _lyricsCache[cacheKey];
    }

    // 1. Try LRCLIB for synced & plain lyrics
    try {
      final queryParams = <String, String>{
        'track_name': cleanTitle,
        'artist_name': cleanArtist,
      };
      if (duration != null && duration.inSeconds > 0) {
        queryParams['duration'] = duration.inSeconds.toString();
      }

      final uri = Uri.https('lrclib.net', '/api/get', queryParams);
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'MyPlayerMusic/1.0 (https://github.com/my_player_music)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final plain = data['plainLyrics']?.toString() ?? '';
        final synced = data['syncedLyrics']?.toString();
        if (plain.trim().isNotEmpty || (synced != null && synced.trim().isNotEmpty)) {
          final res = LyricsResult.parse(plain: plain.trim(), synced: synced?.trim());
          _lyricsCache[cacheKey] = res;
          return res;
        }
      }
    } catch (e) {
      debugPrint('LRCLIB fetch error for "$cleanTitle" by "$cleanArtist": $e');
    }

    // 2. Fallback to Lyrics.ovh for plain lyrics
    try {
      final encArtist = Uri.encodeComponent(cleanArtist);
      final encTitle = Uri.encodeComponent(cleanTitle);
      final uri = Uri.parse('https://api.lyrics.ovh/v1/$encArtist/$encTitle');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final plain = data['lyrics']?.toString() ?? '';
        if (plain.trim().isNotEmpty) {
          final res = LyricsResult.parse(plain: plain.trim());
          _lyricsCache[cacheKey] = res;
          return res;
        }
      }
    } catch (e) {
      debugPrint('Lyrics.ovh fallback error for "$cleanTitle": $e');
    }

    return null;
  }
}

import 'package:flutter/material.dart';

class LyricLine {
  final Duration time;
  final String text;

  const LyricLine({required this.time, required this.text});
}

class LyricsResult {
  final String plainLyrics;
  final String? syncedLyrics;
  final List<LyricLine> lines;
  final bool isSynced;

  const LyricsResult({
    required this.plainLyrics,
    this.syncedLyrics,
    this.lines = const [],
    this.isSynced = false,
  });

  static LyricsResult empty() => const LyricsResult(plainLyrics: '');

  static LyricsResult parse({required String plain, String? synced}) {
    if (synced != null && synced.trim().isNotEmpty) {
      final List<LyricLine> parsedLines = [];
      final regExp = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)');
      for (final rawLine in synced.split('\n')) {
        final match = regExp.firstMatch(rawLine.trim());
        if (match != null) {
          final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
          final seconds = double.tryParse(match.group(2) ?? '0') ?? 0.0;
          final text = match.group(3)?.trim() ?? '';
          if (text.isNotEmpty) {
            parsedLines.add(
              LyricLine(
                time: Duration(milliseconds: (minutes * 60 * 1000 + seconds * 1000).toInt()),
                text: text,
              ),
            );
          }
        }
      }
      if (parsedLines.isNotEmpty) {
        return LyricsResult(
          plainLyrics: plain.isNotEmpty ? plain : parsedLines.map((e) => e.text).join('\n'),
          syncedLyrics: synced,
          lines: parsedLines,
          isSynced: true,
        );
      }
    }
    return LyricsResult(
      plainLyrics: plain,
      lines: const [],
      isSynced: false,
    );
  }
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final Duration duration;
  final String url;
  final String artUrl;
  final List<Color> gradientColors;
  final String lyrics;
  final String? syncedLyrics;
  final String source;
  final bool isFullLength;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.duration,
    required this.url,
    required this.artUrl,
    required this.gradientColors,
    required this.lyrics,
    this.syncedLyrics,
    this.source = 'Monochrome',
    this.isFullLength = true,
  });

  bool get hasRealLyrics =>
      lyrics.trim().isNotEmpty && !lyrics.startsWith('[Monochrome Lossless FLAC]');

  List<LyricLine> get parsedSyncedLyrics {
    if (syncedLyrics == null || syncedLyrics!.trim().isEmpty) return const [];
    final List<LyricLine> list = [];
    final regExp = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)');
    for (final rawLine in syncedLyrics!.split('\n')) {
      final match = regExp.firstMatch(rawLine.trim());
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = double.tryParse(match.group(2) ?? '0') ?? 0.0;
        final text = match.group(3)?.trim() ?? '';
        if (text.isNotEmpty) {
          list.add(
            LyricLine(
              time: Duration(milliseconds: (minutes * 60 * 1000 + seconds * 1000).toInt()),
              text: text,
            ),
          );
        }
      }
    }
    return list;
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    Duration? duration,
    String? url,
    String? artUrl,
    List<Color>? gradientColors,
    String? lyrics,
    String? syncedLyrics,
    String? source,
    bool? isFullLength,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      duration: duration ?? this.duration,
      url: url ?? this.url,
      artUrl: artUrl ?? this.artUrl,
      gradientColors: gradientColors ?? this.gradientColors,
      lyrics: lyrics ?? this.lyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      source: source ?? this.source,
      isFullLength: isFullLength ?? this.isFullLength,
    );
  }

  static final List<List<Color>> _gradientPalette = [
    [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
    [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
    [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
    [const Color(0xFF10B981), const Color(0xFF06B6D4)],
    [const Color(0xFF6366F1), const Color(0xFFA855F7)],
    [const Color(0xFFFF5252), const Color(0xFFFF7A00)],
    [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
    [const Color(0xFFF093FB), const Color(0xFFF5576C)],
    [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
    [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
  ];

  static List<Color> getGradientFor(String key) {
    final hash = key.hashCode.abs();
    return _gradientPalette[hash % _gradientPalette.length];
  }

  factory Song.fromMonochromeJson(Map<String, dynamic> json, {String? category}) {
    final rawId = json['id']?.toString() ?? json['trackId']?.toString() ?? UniqueKey().toString();
    final id = 'mono_$rawId';
    final title = json['title']?.toString().trim() ?? 'Unknown Title';

    String artist = 'Unknown Artist';
    if (json['artistNames'] is List && (json['artistNames'] as List).isNotEmpty) {
      artist = (json['artistNames'] as List).map((e) => e.toString()).join(', ');
    }

    final artwork = json['artwork']?.toString() ?? '';
    final streamUrl = 'https://tracks.monochrome.st/track/$rawId';

    Duration dur = Duration.zero;
    final d = json['duration'];
    if (d is num) {
      dur = Duration(milliseconds: d.toInt());
    }

    return Song(
      id: id,
      title: title,
      artist: artist,
      album: json['albumTitle']?.toString() ?? json['releaseTitle']?.toString() ?? 'Monochrome FLAC',
      genre: category ?? (json['explicit'] == true ? 'Explicit • FLAC' : 'Hi-Res FLAC'),
      duration: dur,
      url: streamUrl,
      artUrl: artwork.isNotEmpty
          ? artwork
          : 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      gradientColors: getGradientFor(id),
      lyrics: '''[Monochrome Lossless FLAC]
Title: $title
Artist: $artist
Quality: Studio Master Lossless FLAC (16/24-bit)
Host: tracks.monochrome.st
Streamed bit-perfect with native byte-range playback.''',
      syncedLyrics: null,
      source: 'Monochrome',
      isFullLength: true,
    );
  }

  static final List<Song> sampleSongs = [
    const Song(
      id: 'mono_154042540746608640',
      title: 'Yellow',
      artist: 'Coldplay',
      album: 'Parachutes',
      genre: 'Hi-Res FLAC',
      duration: Duration(minutes: 4, seconds: 26),
      url: 'https://tracks.monochrome.st/track/154042540746608640',
      artUrl: 'https://tracks.monochrome.st/proxy/mi/154036290327678976-1A01.jpg',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      lyrics: '''Look at the stars
Look how they shine for you
And everything you do
Yeah, they were all yellow

I came along
I wrote a song for you
And all the things you do
And it was called "Yellow"

So then I took my turn
Oh, what a thing to have done
And it was all yellow

Your skin, oh, yeah, your skin and bones
Turn into something beautiful
And you know, you know I love you so
You know I love you so

I swam across
I jumped across for you
Oh, what a thing to do
'Cause you were all yellow
I drew a line
I drew a line for you
Oh, what a thing to do
And it was all yellow

And your skin, oh, yeah, your skin and bones
Turn into something beautiful
And you know, for you, I'd bleed myself dry
For you, I'd bleed myself dry

It's true
Look how they shine for you
Look how they shine for you
Look how they shine for
Look how they shine for you
Look how they shine for you
Look how they shine
Look at the stars
Look how they shine for you
And all the things that you do''',
      syncedLyrics: '''[00:35.66] Look at the stars
[00:38.46] Look how they shine for you
[00:44.17] And everything you do
[00:49.66] Yeah, they were all yellow
[00:52.66] I came along
[00:55.42] I wrote a song for you
[01:00.69] And all the things you do
[01:06.24] And it was called "Yellow"
[01:13.25] So then I took my turn
[01:17.25] Oh, what a thing to have done
[01:22.48] And it was all yellow
[01:30.73] Your skin, oh, yeah, your skin and bones
[01:36.72] Turn into something beautiful
[01:42.34] And you know, you know I love you so
[01:50.51] You know I love you so
[02:15.48] I swam across
[02:18.18] I jumped across for you
[02:23.32] Oh, what a thing to do
[02:29.14] 'Cause you were all yellow
[02:32.03] I drew a line
[02:34.91] I drew a line for you
[02:40.30] Oh, what a thing to do
[02:45.91] And it was all yellow
[02:53.74] And your skin, oh, yeah, your skin and bones
[02:59.77] Turn into something beautiful
[03:05.35] And you know, for you, I'd bleed myself dry
[03:13.63] For you, I'd bleed myself dry
[03:37.82] It's true
[03:41.18] Look how they shine for you
[03:46.70] Look how they shine for you
[03:52.11] Look how they shine for
[03:57.84] Look how they shine for you
[04:03.26] Look how they shine for you
[04:09.07] Look how they shine
[04:11.90] Look at the stars
[04:14.33] Look how they shine for you
[04:19.99] And all the things that you do''',
      source: 'Monochrome',
      isFullLength: true,
    ),
    const Song(
      id: 'mono_166150312078221312',
      title: 'Hati-Hati di Jalan',
      artist: 'Tulus',
      album: 'Manusia',
      genre: 'Hi-Res FLAC',
      duration: Duration(minutes: 4, seconds: 2),
      url: 'https://tracks.monochrome.st/track/166150312078221312',
      artUrl: 'https://tracks.monochrome.st/proxy/mi/166130602897604608-1A01.jpg',
      gradientColors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
      lyrics: '''Perjalanan membawamu
Bertemu denganku, ku bertemu kamu
Sepertimu yang kucari
Konon aku juga s'perti yang kaucari

Kukira kita Asam dan Garam
Dan kita bertemu di Belanga
Kisah yang ternyata tak seindah itu

Kukira kita akan bersama
Begitu banyak yang sama
Latarmu dan latarku

Kukira takkan ada kendala
Kukira ini 'kan mudah
Kau-aku jadi kita

Kasih sayangmu membekas
Redam kini sudah pijar istimewa
Entah apa maksud dunia
Tentang ujung cerita, kita tak bersama

Semoga rindu ini menghilang
Konon katanya waktu sembuhkan
Akan adakah lagi yang sepertimu?

Kukira kita akan bersama
Begitu banyak yang sama
Latarmu dan latarku

Kukira takkan ada kendala
Kukira ini 'kan mudah
Kau-aku jadi kita

Kau melanjutkan perjalananmu
Ku melanjutkan perjalananku

Kukira kita akan bersama
Begitu banyak yang sama
Latarmu dan latarku

Kukira takkan ada kendala
Kukira ini 'kan mudah
Kau-aku jadi kita
Kukira kita akan bersama

Hati-hati di jalan''',
      syncedLyrics: '''[00:13.24] Perjalanan membawamu
[00:18.10] Bertemu denganku, ku bertemu kamu
[00:26.58] Sepertimu yang kucari
[00:31.57] Konon aku juga s'perti yang kaucari
[00:40.32] Kukira kita Asam dan Garam
[00:43.93] Dan kita bertemu di Belanga
[00:47.02] Kisah yang ternyata tak seindah itu
[00:57.01] Kukira kita akan bersama
[01:01.79] Begitu banyak yang sama
[01:05.01] Latarmu dan latarku
[01:10.24] Kukira takkan ada kendala
[01:15.17] Kukira ini 'kan mudah
[01:18.45] Kau-aku jadi kita
[01:23.12] Kasih sayangmu membekas
[01:28.12] Redam kini sudah pijar istimewa
[01:36.68] Entah apa maksud dunia
[01:41.49] Tentang ujung cerita, kita tak bersama
[01:50.30] Semoga rindu ini menghilang
[01:53.73] Konon katanya waktu sembuhkan
[01:57.06] Akan adakah lagi yang sepertimu?
[02:03.66] Kukira kita akan bersama
[02:08.49] Begitu banyak yang sama
[02:11.63] Latarmu dan latarku
[02:16.99] Kukira takkan ada kendala
[02:21.78] Kukira ini 'kan mudah
[02:25.06] Kau-aku jadi kita
[02:31.03] Kau melanjutkan perjalananmu
[02:37.83] Ku melanjutkan perjalananku
[02:56.97] Kukira kita akan bersama
[03:01.75] Begitu banyak yang sama
[03:05.09] Latarmu dan latarku
[03:10.38] Kukira takkan ada kendala
[03:15.13] Kukira ini 'kan mudah
[03:18.36] Kau-aku jadi kita
[03:21.70] Kukira kita akan bersama
[03:37.77] Hati-hati di jalan''',
      source: 'Monochrome',
      isFullLength: true,
    ),
    const Song(
      id: 'mono_154042536988512256',
      title: 'Viva La Vida',
      artist: 'Coldplay',
      album: 'Viva La Vida or Death and All His Friends',
      genre: 'Hi-Res FLAC',
      duration: Duration(minutes: 4, seconds: 2),
      url: 'https://tracks.monochrome.st/track/154042536988512256',
      artUrl: 'https://tracks.monochrome.st/proxy/mi/154036281569972224-1A01.jpg',
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      lyrics: '''I used to rule the world
Seas would rise when I gave the word
Now in the morning I sleep alone
Sweep the streets I used to own

I used to roll the dice
Feel the fear in my enemy's eyes
Listen as the crowd would sing
Now the old king is dead, long live the king!

One minute I held the key
Next the walls were closed on me
And I discovered that my castles stand
Upon pillars of salt and pillars of sand

I hear Jerusalem bells a-ringin'
Roman Cavalry choirs are singin'
Be my mirror, my sword and shield
My missionaries in a foreign field
For some reason I can't explain
Once you'd gone there was never
Never an honest word
And that was when I ruled the world''',
      syncedLyrics: '''[00:27.10] I used to rule the world
[00:30.95] Seas would rise when I gave the word
[00:35.40] Now in the morning I sleep alone
[00:40.00] Sweep the streets I used to own
[00:52.45] I used to roll the dice
[00:56.70] Feel the fear in my enemy's eyes
[01:00.90] Listen as the crowd would sing
[01:05.00] Now the old king is dead, long live the king!
[01:09.50] One minute I held the key
[01:13.80] Next the walls were closed on me
[01:18.00] And I discovered that my castles stand
[01:21.90] Upon pillars of salt and pillars of sand
[01:26.50] I hear Jerusalem bells a-ringin'
[01:30.90] Roman Cavalry choirs are singin'
[01:35.30] Be my mirror, my sword and shield
[01:39.60] My missionaries in a foreign field
[01:43.90] For some reason I can't explain
[01:48.20] Once you'd gone there was never
[01:51.50] Never an honest word
[01:54.60] And that was when I ruled the world''',
      source: 'Monochrome',
      isFullLength: true,
    ),
    const Song(
      id: 'mono_154078950073569280',
      title: 'Popular',
      artist: 'The Weeknd, Playboi Carti, Madonna',
      album: 'The Idol Vol. 1',
      genre: 'Hi-Res FLAC',
      duration: Duration(minutes: 3, seconds: 35),
      url: 'https://tracks.monochrome.st/track/154078950073569280',
      artUrl: 'https://tracks.monochrome.st/proxy/mi/154047393183043584-1A01.jpg',
      gradientColors: [Color(0xFFFF5252), Color(0xFFFF7A00)],
      lyrics: '''I've seen the devil, yeah, I met him in Batavia
Cash in every safe, living like a savior
Money on my mind, never looking behind
Cause I know that she's living for the thrill
Yeah, she's running through the city like a criminal
Looking for the fame, thinking it's medicinal
I know what she wants, she wants to be popular''',
      syncedLyrics: null,
      source: 'Monochrome',
      isFullLength: true,
    ),
  ];
}

# 🎵 My Player Music

Aplikasi pemutar musik modern (Music Player) berbasis **Flutter** dengan tampilan antarmuka *Dark Glassmorphism* yang elegan, fitur audio streaming real-time, visualisasi equalizer animasi, dan kontrol playback lengkap.

---

## ✨ Fitur Utama

- **🎧 Audio Playback Real-time**: Menggunakan `audioplayers` untuk memutar audio streaming demo berkualitas tinggi secara asinkron.
- **🎛️ Full Player Controls**:
  - Play, Pause, Resume, Stop
  - Scrubbing / Seek bar dengan durasi menit & detik presisi
  - Next track & Previous track
  - Mode **Shuffle** (acak lagu) & **Repeat** (ulang lagu)
  - Slider volume kontrol
- **💿 Rotating Vinyl & Ambient Glow**:
  - Animasi piringan hitam (vinyl disc) yang berputar halus saat musik diputar.
  - Ambient glow dinamis di latar belakang yang menyesuaikan warna tema lagu.
- **📊 Animated Equalizer**: Visualisasi 4 bar equalizer aktif yang bergerak dinamis saat audio berputar.
- **📜 Playing Queue & Reorder**: Bottom sheet antrean lagu yang sedang diputar untuk berpindah lagu dengan mudah.
- **🎤 Lirik Lagu (Lyrics Modal)**: Fitur melihat lirik lagu dengan tampilan bottom sheet modern.
- **❤️ Sistem Favorit**: Kemampuan menandai lagu favorit dan memfilter lagu berdasarkan kategori / genre.
- **🔍 Fitur Pencarian Cepat**: Filter pencarian instan berdasarkan judul lagu, nama artis, dan album.
- **📱 Floating Mini Player**: Pemutar musik mini persisten di bagian bawah layar dengan progress bar dan tombol cepat (tap untuk membuka Full Player dengan transisi halus).

---

## 📂 Struktur Project

```text
lib/
├── main.dart                      # Entry point aplikasi & konfigurasi tema
├── models/
│   └── song.dart                  # Model Song & dataset sample playlist
├── services/
│   └── audio_manager.dart         # State management & wrapper AudioPlayer (audioplayers)
├── theme/
│   └── app_theme.dart             # Dark neon color palette & tipografi Google Fonts
├── widgets/
│   ├── animated_equalizer.dart    # Visualizer bar equalizer animasi
│   ├── glass_box.dart             # Glassmorphism container dengan backdrop blur
│   ├── mini_player.dart           # Floating bottom mini player
│   └── song_tile.dart             # Card list item lagu
└── screens/
    ├── home_screen.dart           # Halaman utama (kategori, search, featured, all songs)
    ├── now_playing_screen.dart    # Halaman full player (vinyl, scrub bar, controls, lyrics)
    └── queue_sheet.dart           # Modal bottom sheet antrean lagu
```

---

## 🚀 Cara Menjalankan Project

1. Buka terminal dan masuk ke direktori project:
   ```bash
   cd "/Volumes/LEXAR E6/Data Penting/Project/Mobile/my_player_music"
   ```

2. Unduh semua dependensi:
   ```bash
   flutter pub get
   ```

3. Jalankan aplikasi pada simulator atau perangkat fisik:
   ```bash
   flutter run
   ```

4. Menjalankan pengujian (smoke test):
   ```bash
   flutter test
   ```

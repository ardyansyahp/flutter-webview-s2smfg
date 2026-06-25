# flutter-webview-s2smfg

Aplikasi Android (Flutter) yang berfungsi sebagai **WebView wrapper + Print Bridge** untuk sistem manufacturing [S2SMFG](https://s2smfg.biz.id).

---

## Deskripsi

Aplikasi ini membungkus halaman web S2SMFG (`https://s2smfg.biz.id/manufacturing/inject`) di dalam WebView Android, dan menyediakan **JavaScript Bridge** (`AndroidPrintChannel`) yang memungkinkan halaman web mengirim perintah cetak ZPL langsung ke printer Zebra/ZPL di jaringan lokal pabrik melalui TCP Socket (port 9100).

### Arsitektur

```
Halaman Web Laravel (s2smfg.biz.id)
    ↓  JavaScript Bridge: AndroidPrintChannel.postMessage({ip, data})
Flutter WebView (Tablet Android di pabrik)
    ↓  TCP Socket (LAN lokal, port 9100)
Printer ZPL / Zebra
```

---

## Fitur

- ✅ **WebView fullscreen** — membuka halaman production S2SMFG
- ✅ **Print Bridge** — menerima perintah cetak dari halaman web dan mengirim raw ZPL ke printer melalui TCP Socket (port 9100)
- ✅ **Camera permission** — meminta izin kamera untuk fitur QR scan di halaman web
- ✅ **URL Settings** — user bisa mengganti URL target VPS langsung dari dalam aplikasi
- ✅ **Progress indicator** — loading bar saat halaman sedang dimuat

---

## Prasyarat

- Flutter SDK ≥ 3.12.2 / Dart SDK ^3.12.2
- Android device (minSdk 21)
- Akses ke jaringan lokal pabrik (untuk koneksi ke printer)
- Server S2SMFG aktif di `https://s2smfg.biz.id`

---

## Dependensi Utama

| Package | Versi | Kegunaan |
|---------|-------|----------|
| `webview_flutter` | ^4.8.0 | WebView engine di Android |
| `permission_handler` | ^11.3.1 | Request izin kamera Android |

---

## Cara Build (Android)

```bash
# 1. Install dependencies
flutter pub get

# 2. Build APK (debug)
flutter build apk --debug

# 3. Build APK (release)
flutter build apk --release

# APK output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Cara Pakai

1. Install APK di tablet Android yang terhubung ke jaringan LAN pabrik
2. Buka aplikasi → halaman S2SMFG manufacturing/inject akan terbuka
3. Untuk mengganti URL server: tap ikon **Settings** (⚙️) di kanan atas
4. Setting IP printer terlebih dahulu di halaman web S2SMFG sebelum mencetak

---

## JavaScript Bridge — Cara Kerja Print

Halaman web mengirim perintah cetak via JavaScript:

```javascript
// Di halaman Laravel (process.blade.php)
AndroidPrintChannel.postMessage(JSON.stringify({
  ip: "192.168.1.100",  // IP printer di LAN pabrik
  data: "^XA...^XZ"    // ZPL string
}));
```

App Flutter menangkap pesan ini dan membuka TCP Socket ke printer secara langsung dari tablet, sehingga tidak perlu melewati server VPS.

---

## Hubungan dengan Repo Lain

- **Backend/Web**: [ardyansyahp/s2smfg](https://github.com/ardyansyahp/s2smfg) — Laravel application (server-side)
- **Driver App**: [ardyansyahp/flutter-driverapp-s2smfg](https://github.com/ardyansyahp/flutter-driverapp-s2smfg) — Aplikasi driver terpisah

# Bug Reports & Resolution Log

---

# Bug #1: Emulator Force Close on Launch

## 1. Ringkasan Masalah
Saat aplikasi dijalankan di emulator Android (`sdk gphone64 x86_64` / Android 16 API 36), aplikasi langsung mengalami **force close (crash saat startup)** dan keluar ke home screen emulator.

---

## 2. Investigasi & Akar Masalah (Root Cause)

Berdasarkan pemeriksaan log sistem Android melalui `adb logcat`:

```text
E AndroidRuntime: FATAL EXCEPTION: main
E AndroidRuntime: Process: com.micinvpn.app, PID: 8549
E AndroidRuntime: java.lang.RuntimeException: Unable to instantiate activity ComponentInfo{com.micinvpn.app/com.micinvpn.app.MainActivity}
Caused by: java.lang.ClassNotFoundException: Didn't find class "com.micinvpn.app.MainActivity" on path: DexPathList[...]
```

### Penyebab Utama:
1. **Mismatch Package & Directory Structure pada Kotlin MainActivity**:
   - Nilai `namespace` dan `applicationId` di `build.gradle.kts` telah diubah menjadi `com.micinvpn.app` sesuai spesifikasi `issue.md`.
   - Namun, file `MainActivity.kt` bawaan Flutter scaffolding masih berada di direktori `android/app/src/main/kotlin/com/micinvpn/micinvpn/MainActivity.kt` dengan deklarasi `package com.micinvpn.micinvpn`.
   - Android OS mencoba memuat class `com.micinvpn.app.MainActivity` sesuai deklarasi Manifest, sehingga menghasilkan `ClassNotFoundException`.

2. **Native Library Packaging untuk OpenVPN Engine**:
   - Plugin `openvpn_flutter` menggunakan engine native C/C++ (`ics-openvpn` / OpenVPN 2.7).
   - Pada Android Gradle Plugin (AGP) versi modern, library `.so` tidak diekstrak secara default (`useLegacyPackaging = false`). Hal ini menyebabkan runtime OpenVPN gagal diekstrak saat inisialisasi native process.

---

## 3. Langkah Perbaikan (Resolution Steps)

1. **Sinkronisasi Package dan Relokasi MainActivity.kt**:
   - Memindahkan `MainActivity.kt` ke direktori paket yang benar: `android/app/src/main/kotlin/com/micinvpn/app/MainActivity.kt`.
   - Memperbarui deklarasi package di dalam file:
     ```kotlin
     package com.micinvpn.app

     import io.flutter.embedding.android.FlutterActivity

     class MainActivity : FlutterActivity()
     ```

2. **Konfigurasi `useLegacyPackaging` di `build.gradle.kts`**:
   - Menambahkan konfigurasi packaging di `android/app/build.gradle.kts` agar library native OpenVPN diekstrak dengan baik oleh sistem Android:
     ```kotlin
     android {
         ...
         packaging {
             jniLibs {
                 useLegacyPackaging = true
             }
         }
     }
     ```

---

## 4. Hasil Verifikasi

1. **Build Ulang**:
   - Menjalankan `flutter build apk --debug` $\rightarrow$ Berhasil tanpa error.
2. **Pengujian pada Emulator**:
   - Instalasi APK hasil build: `adb install -r build/app/outputs/flutter-apk/app-debug.apk` $\rightarrow$ `Success`.
   - Menjalankan aplikasi: `adb shell am start -n com.micinvpn.app/.MainActivity` $\rightarrow$ Berhasil.
   - Pengecekan proses aktif: `adb shell "pidof com.micinvpn.app"` $\rightarrow$ Proses aktif (PID `8681`), aplikasi stabil berjalan di foreground tanpa force close.

---

# Bug #2: VPN Gate API Fetch TimeoutException (Future not completed)

## 1. Ringkasan Masalah
Pada saat aplikasi melakukan request ke API VPN Gate (`https://www.vpngate.net/api/iphone/`), aplikasi menampilkan error:
```text
Exception: Gagal mengambil server vpn TimeoutException after 0:00:15.000000: Future not completed
```
Pada debug network, koneksi HTTP mengembalikan status 200 namun proses transfer body tertahan (pending) sehingga timeout 15 detik tercapai sebelum seluruh stream data selesai diunduh.

---

## 2. Investigasi & Akar Masalah (Root Cause)

1. **Ukuran Payload CSV Sangat Besar (> 1.3 MB Plain Text)**:
   - Endpoint `https://www.vpngate.net/api/iphone/` mengembalikan seluruh daftar publik server VPN Gate di seluruh dunia, lengkap dengan konfigurasi OpenVPN Base64 panjang untuk setiap server (rata-rata 1.3 MB - 2.5 MB).
2. **Server Throttling & Bandwidth Jaringan**:
   - Server publik VPN Gate di Jepang sering kali menerapkan throttling kecepatan transfer pada client non-browser atau koneksi jaringan emulator/mobile.
3. **Hardcoded Timeout Terlalu Ketat (15 Detik)**:
   - Pemanggilan `http.get(...).timeout(Duration(seconds: 15))` membatasi waktu total koneksi + unduhan seluruh body 1.3 MB. Begitu batas 15 detik terlewati, Dart runtime melempar `TimeoutException: Future not completed`, membatalkan stream yang sebenarnya sedang berlangsung.
4. **Main UI Thread Blocking**:
   - Parsing teks CSV berukuran 1.3 MB pada main thread dapat menyebabkan frame drop (jank) saat payload diterima.

---

## 3. Langkah Perbaikan (Resolution Steps)

1. **Pemisahan Streaming Timeout**:
   - Menggunakan `http.Request` dan `streamedResponse` dengan timeout bertahap:
     - 30 detik untuk *connection establishment & response headers* (status code 200).
     - 45 detik untuk *body payload streaming* agar download data > 1.3 MB dapat selesai tuntas meskipun koneksi lambat.
2. **Multi-Endpoint Fallback (Mirrors)**:
   - Menambahkan daftar mirror URL VPN Gate:
     - `https://www.vpngate.net/api/iphone/` (Primary)
     - `http://www.vpngate.net/api/iphone/` (HTTP fallback)
     - `https://download.vpngate.jp/api/iphone/` (Mirror regional JP)
   - Jika endpoint pertama mengalami kegagalan/timeout, service secara otomatis beralih ke endpoint berikutnya.
3. **In-Memory Caching (5 Menit)**:
   - Menyimpan daftar server yang berhasil diunduh ke dalam cache lokal memori selama 5 menit.
   - Mengurangi request berulang ke VPN Gate yang memperberat jaringan dan mencegah timeout saat navigasi antar-halaman.
   - Opsi `forceRefresh: true` disediakan saat pengguna menekan tombol Refresh atau Pull-to-Refresh.
4. **Isolate Background Parsing (`compute`)**:
   - Proses parsing CSV dipindahkan ke background isolate menggunakan `compute(_parseCsvInIsolate, rawCsv)` sehingga rendering UI tetap mulus pada 60 fps.

---

## 4. Hasil Verifikasi

1. **Static Analysis & Tests**:
   - `flutter analyze` $\rightarrow$ `No issues found! (0 errors/warnings)`
   - `flutter test` $\rightarrow$ `All tests passed!`
2. **Pengujian Aplikasi**:
   - Request ke API tidak lagi terputus prematur pada detik ke-15.
   - Saat payload selesai diunduh, server card langsung tampil di layar secara responsif tanpa error `TimeoutException`.

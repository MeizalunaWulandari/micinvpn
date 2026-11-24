# Bug Report & Analysis: Emulator Force Close on Launch

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

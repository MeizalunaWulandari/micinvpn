# Task Specifications & Roadmap: Micin VPN

Dokumen ini berisi spesifikasi kebutuhan dan daftar tugas tingkat tinggi (high-level) untuk implementasi proyek **Micin VPN**. Dokumen ini dirancang sebagai panduan bagi developer atau AI agent untuk dieksekusi secara bertahap melalui sistem Pull Request.

---

## Ringkasan Proyek

| Parameter | Detail |
| :--- | :--- |
| **Nama Aplikasi** | Micin VPN |
| **Package ID** | `com.micinvpn.app` |
| **Target Platform** | Android Only |
| **Protokol VPN** | OpenVPN (`.ovpn`) |
| **Sumber Server Publik** | VPN Gate API (`https://www.vpngate.net/api/iphone`) |

---

## Aturan Repositori & Alur Kerja (Workflow)

- **Strict Pull Request Workflow**: Setiap fitur, perbaikan bug, atau perubahan kode **wajib** dilakukan pada branch baru (contoh: `feat/scaffold-app`, `feat/vpn-gate-service`) dan digabungkan ke branch utama (`master`/`main`) hanya melalui **Pull Request (PR)**.
- **Direct Commit Prohibited**: Dilarang keras melakukan commit langsung ke branch utama (`master`/`main`).
- **Dokumentasi Terpadu**: Buat dan perbarui `README.md` pada setiap modul atau tahapan proyek untuk menjelaskan arsitektur, setup, dan cara penggunaan.

---

## Milestone 1: Inisialisasi & Setup Repositori

### Issue #1: Repository Setup & Git Governance
- **Tujuan**: Menyiapkan repositori lokal dan remote GitHub dengan standar kolaborasi yang rapi.
- **Tugas**:
  - Inisialisasi Git di direktori kerja proyek (`git init`).
  - Buat repositori remote di GitHub menggunakan GitHub CLI (`gh`) dengan nama repositori yang sama dengan folder ini. 
  - repositori public
  - Buat `README.md` utama yang menjelaskan profil proyek, arsitektur dasar, dan petunjuk kontribusi.
  - Terapkan kebijakan branch: set branch default, siapkan branch perlindungan atau aturan review PR.

---

## Milestone 2: Flutter Android Scaffolding

### Issue #2: Flutter Project Setup (Android Only)
- **Tujuan**: Membuat kerangka aplikasi Flutter yang dikonfigurasi khusus untuk platform Android.
- **Tugas**:
  - Inisialisasi proyek Flutter baru yang hanya menargetkan platform Android.
  - Konfigurasikan Package Name / Application ID menjadi `com.micinvpn.app`.
  - Konfigurasikan App Name menjadi `Micin VPN`.
  - Konfigurasikan izin (permissions) yang dibutuhkan Android untuk layanan VPN dan akses file (bila diperlukan).
  - Tambahkan pustaka dasar yang dibutuhkan (OpenVPN wrapper/native bridge, HTTP client, CSV parser, state management).
  - Stucture flutter MVVC 
---

## Milestone 3: Integrasi Data & VPN Gate API

### Issue #3: VPN Gate API Client & CSV Parser
- **Tujuan**: Mengambil dan mengolah daftar server OpenVPN publik dari VPN Gate.
- **Tugas**:
  - Buat service untuk melakukan fetching data dari endpoint: `https://www.vpngate.net/api/iphone`.
  - Implementasikan parser data CSV respons dari VPN Gate menjadi model data terstruktur.
  - Ekstrak atribut penting dari tiap server:
    - Country (Nama & Kode Negara / Bendera)
    - Hostname / IP Address
    - Konfigurasi OpenVPN (Base64 `.ovpn` configuration string)
  - Tangani error handling (koneksi terputus, timeout, validasi respons CSV).

---

## Milestone 4: Tampilan & Interaksi Pengguna (UI/UX)

### Issue #4: Server List & Card Component
- **Tujuan**: Menampilkan daftar server VPN yang tersedia dalam bentuk kartu informatif.
- **Tugas**:
  - Buat komponen Card pada Home Page dengan struktur informasi:
    - **Country**: Menampilkan nama/kode negara server.
    - **Hostname**: Menampilkan alamat host server.
    - **Connect Action**: Tombol/aksi untuk memilih dan memulai koneksi ke server tersebut.
  - Sediakan indikator status loading saat fetching data dan fitur refresh daftar server.

### Issue #5: Connection State & Active VPN Screen
- **Tujuan**: Transisi tampilan antarmuka saat server dipilih dan status koneksi berubah.
- **Tugas**:
  - Implementasikan state koneksi VPN (Disconnected, Connecting, Connected, Disconnecting).
  - Beralih tampilan layar utama (atau panel status) saat server telah terkonfigurasi:
    - Menampilkan informasi server aktif yang sedang terhubung.
    - Tombol Connect / Disconnect yang intuitif.
    - Indikator status koneksi saat VPN aktif.

---

## Milestone 5: Fitur Custom Configuration (Import .ovpn)

### Issue #6: Custom OpenVPN Config Importer
- **Tujuan**: Memungkinkan pengguna memakai file konfigurasi OpenVPN milik sendiri.
- **Tugas**:
  - Sediakan menu/tombol untuk mengimpor file lokal pengguna.
  - Batasi dan validasi format file agar hanya menerima ekstensi `.ovpn`.
  - Parsing dan simpan konfigurasi yang diimpor ke dalam koneksi manajer.
  - Sediakan opsi untuk langsung menghubungkan VPN menggunakan konfigurasi yang baru saja diimpor.

---

## Panduan untuk Pelaksana / Developer

1. Kerjakan tugas berdasarkan nomor Issue secara berurutan.
2. Setiap pengerjaan Issue dimulai dengan membuat branch baru: `feature/issue-<nomor>-<deskripsi-singkat>`.
3. Pastikan kode lulus analisis/linter Flutter sebelum membuat Pull Request.
4. Buat Pull Request dengan penjelasan ringkas mengenai perubahan yang dilakukan, lalu lakukan review sebelum di-merge ke branch utama.

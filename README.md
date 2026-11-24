# Micin VPN

Micin VPN adalah aplikasi VPN berbasis Flutter untuk platform Android yang menggunakan konfigurasi OpenVPN (`.ovpn`) dan mengambil daftar server publik dari VPN Gate API.

## Fitur Utama

- **Android Native Integration**: Didesain khusus untuk platform Android menggunakan implementasi OpenVPN.
- **VPN Gate API Integration**: Mengambil server publik terupdate secara dinamis dari `https://www.vpngate.net/api/iphone` (format CSV).
- **Server Discovery Card**: Informasi negara, bendera/kode, hostname, serta tombol koneksi instan.
- **Connection Dashboard**: Panel status koneksi real-time (Disconnected, Connecting, Connected, Disconnecting).
- **Custom Config Importer**: Mendukung import file konfigurasi `.ovpn` kustom dari penyimpanan lokal pengguna.

## Spesifikasi Teknis

- **Package Name**: `com.micinvpn.app`
- **Application Name**: `Micin VPN`
- **Target Platform**: Android Only
- **Protokol**: OpenVPN (`.ovpn`)

## Panduan Kontribusi & Alur Kerja Git

Proyek ini menerapkan **Strict Pull Request Workflow**:
1. Dilarang melakukan commit langsung ke branch `master`.
2. Setiap fitur atau perbaikan dibuat melalui branch baru (contoh: `feat/server-list`, `feat/ovpn-import`).
3. Penggabungan kode ke `master` hanya dapat dilakukan melalui **Pull Request (PR)**.

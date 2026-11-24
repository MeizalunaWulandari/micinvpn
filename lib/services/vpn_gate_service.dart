import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/vpn_server.dart';

class VpnGateService {
  // Mirror list in case primary endpoint is slow or throttled
  static const List<String> apiEndpoints = [
    'https://www.vpngate.net/api/iphone/',
    'http://www.vpngate.net/api/iphone/',
    'https://download.vpngate.jp/api/iphone/',
  ];

  /// In-memory cache to prevent redundant heavy network downloads
  static List<VpnServer>? _cachedServers;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Fetches VPN Gate server list with streaming, timeout resilience, fallback mirrors, and background isolate parsing
  Future<List<VpnServer>> fetchServers({bool forceRefresh = false}) async {
    // Return cached servers if available and valid
    if (!forceRefresh &&
        _cachedServers != null &&
        _cachedServers!.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedServers!;
    }

    Object? lastError;

    for (final endpoint in apiEndpoints) {
      try {
        final client = http.Client();
        final request = http.Request('GET', Uri.parse(endpoint));
        request.headers['User-Agent'] =
            'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
        request.headers['Accept-Encoding'] = 'gzip, deflate';

        // 1. Initial connection & header timeout: 30 seconds
        final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 30),
        );

        if (streamedResponse.statusCode != 200) {
          client.close();
          continue;
        }

        // 2. Stream body reception with safe 45-second overall timeout
        final responseBytes = await streamedResponse.stream
            .toBytes()
            .timeout(const Duration(seconds: 45));
        client.close();

        final rawCsv = utf8.decode(responseBytes, allowMalformed: true);

        // 3. Offload CPU-intensive parsing to background isolate to keep UI 60fps
        final servers = await compute(_parseCsvInIsolate, rawCsv);

        if (servers.isNotEmpty) {
          _cachedServers = servers;
          _lastFetchTime = DateTime.now();
          return servers;
        }
      } catch (e) {
        lastError = e;
        // Try next fallback endpoint
        continue;
      }
    }

    if (_cachedServers != null && _cachedServers!.isNotEmpty) {
      // Graceful fallback to existing cache if network failed
      return _cachedServers!;
    }

    throw Exception(
      'Gagal mengambil daftar server VPN Gate: koneksi lambat atau terputus ($lastError). '
      'Silakan periksa koneksi internet Anda atau coba lagi.',
    );
  }

  /// Top-level or static function for compute() isolate parsing
  static List<VpnServer> _parseCsvInIsolate(String csvData) {
    final List<VpnServer> servers = [];
    final lines = LineSplitter.split(csvData);

    List<String>? headers;

    int hostIdx = -1;
    int ipIdx = -1;
    int scoreIdx = -1;
    int pingIdx = -1;
    int speedIdx = -1;
    int countryLongIdx = -1;
    int countryShortIdx = -1;
    int sessionsIdx = -1;
    int configIdx = -1;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('*')) {
        continue;
      }

      final columns = _splitCsvLine(trimmed);

      if (headers == null) {
        // First non-comment line is header
        headers = columns.map((e) => e.replaceAll('#', '').trim().toLowerCase()).toList();
        hostIdx = headers.indexOf('hostname');
        ipIdx = headers.indexOf('ip');
        scoreIdx = headers.indexOf('score');
        pingIdx = headers.indexOf('ping');
        speedIdx = headers.indexOf('speed');
        countryLongIdx = headers.indexOf('countrylong');
        countryShortIdx = headers.indexOf('countryshort');
        sessionsIdx = headers.indexOf('numvpnsessions');
        configIdx = headers.indexOf('openvpn_configdata_base64');
        continue;
      }

      if (columns.length <= 1) continue;

      try {
        final hostname = (hostIdx != -1 && hostIdx < columns.length) ? columns[hostIdx] : '';
        final ip = (ipIdx != -1 && ipIdx < columns.length) ? columns[ipIdx] : '';
        final score = (scoreIdx != -1 && scoreIdx < columns.length) ? int.tryParse(columns[scoreIdx]) ?? 0 : 0;
        final ping = (pingIdx != -1 && pingIdx < columns.length) ? int.tryParse(columns[pingIdx]) ?? 0 : 0;
        final speed = (speedIdx != -1 && speedIdx < columns.length) ? int.tryParse(columns[speedIdx]) ?? 0 : 0;
        final countryLong = (countryLongIdx != -1 && countryLongIdx < columns.length) ? columns[countryLongIdx] : 'Unknown';
        final countryShort = (countryShortIdx != -1 && countryShortIdx < columns.length) ? columns[countryShortIdx] : '--';
        final sessions = (sessionsIdx != -1 && sessionsIdx < columns.length) ? int.tryParse(columns[sessionsIdx]) ?? 0 : 0;
        final configData = (configIdx != -1 && configIdx < columns.length) ? columns[configIdx] : '';

        if (configData.isNotEmpty && (hostname.isNotEmpty || ip.isNotEmpty)) {
          servers.add(VpnServer(
            hostname: hostname,
            ip: ip,
            score: score,
            ping: ping,
            speed: speed,
            countryLong: countryLong,
            countryShort: countryShort,
            vpnSessionsNum: sessions,
            openVpnConfigDataBase64: configData,
          ));
        }
      } catch (_) {
        // Skip malformed rows safely
      }
    }

    return servers;
  }

  /// Fast non-blocking CSV line splitter taking care of commas
  static List<String> _splitCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer sb = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == ',' && !insideQuotes) {
        result.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    result.add(sb.toString().trim());
    return result;
  }
}

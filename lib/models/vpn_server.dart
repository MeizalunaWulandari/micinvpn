import 'dart:convert';

class VpnServer {
  final String hostname;
  final String ip;
  final int score;
  final int ping;
  final int speed;
  final String countryLong;
  final String countryShort;
  final int vpnSessionsNum;
  final String openVpnConfigDataBase64;
  final bool isCustom;

  VpnServer({
    required this.hostname,
    required this.ip,
    required this.score,
    required this.ping,
    required this.speed,
    required this.countryLong,
    required this.countryShort,
    required this.vpnSessionsNum,
    required this.openVpnConfigDataBase64,
    this.isCustom = false,
  });

  /// Decode base64 to plain ovpn configuration text with cipher fallback compatibility
  String get configContent {
    String content;
    if (isCustom) {
      content = openVpnConfigDataBase64;
    } else {
      try {
        content = utf8.decode(base64.decode(openVpnConfigDataBase64));
      } catch (_) {
        content = openVpnConfigDataBase64;
      }
    }

    // Ensure compatibility with older VPN Gate servers using BF-CBC or unnegotiated ciphers on OpenVPN 2.7 / OpenSSL 3.5
    final buffer = StringBuffer();
    buffer.writeln(content);

    // If configuration does not specify modern data-ciphers, provide fallback ciphers and legacy provider
    if (!content.contains('data-ciphers')) {
      buffer.writeln('data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305:BF-CBC');
      buffer.writeln('data-ciphers-fallback BF-CBC');
    }
    if (!content.contains('providers')) {
      buffer.writeln('providers legacy default');
    }

    return buffer.toString();
  }

  /// Create custom VPN server from user imported file
  factory VpnServer.fromCustomConfig({
    required String name,
    required String configText,
  }) {
    return VpnServer(
      hostname: name,
      ip: 'Custom IP',
      score: 0,
      ping: 0,
      speed: 0,
      countryLong: 'Custom Config',
      countryShort: 'CUSTOM',
      vpnSessionsNum: 0,
      openVpnConfigDataBase64: configText,
      isCustom: true,
    );
  }
}

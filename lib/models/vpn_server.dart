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

  /// Decode base64 to plain ovpn configuration text
  String get configContent {
    if (isCustom) {
      return openVpnConfigDataBase64;
    }
    try {
      return utf8.decode(base64.decode(openVpnConfigDataBase64));
    } catch (_) {
      return openVpnConfigDataBase64;
    }
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

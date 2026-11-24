import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/vpn_server.dart';

class VpnGateService {
  static const String apiUrl = 'https://www.vpngate.net/api/iphone/';

  /// Fetches VPN Gate server list and parses CSV content
  Future<List<VpnServer>> fetchServers() async {
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load VPN servers (HTTP ${response.statusCode})');
      }

      final body = response.body;
      return parseVpnGateCsv(body);
    } catch (e) {
      throw Exception('Gagal mengambil daftar server VPN Gate: $e');
    }
  }

  /// Parses raw CSV string from VPN Gate
  List<VpnServer> parseVpnGateCsv(String csvData) {
    final List<VpnServer> servers = [];

    // Clean up lines starting with comment '*' or empty lines
    final lines = csvData.split('\n');
    final validLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('*')) {
        continue;
      }
      validLines.add(trimmed);
    }

    if (validLines.isEmpty) return servers;

    final csvContent = validLines.join('\n');
    final List<List<dynamic>> rows = csv.decode(csvContent);

    if (rows.length <= 1) return servers;

    // Header row usually:
    // #HostName,IP,Score,Ping,Speed,CountryLong,CountryShort,NumVpnSessions,Uptime,TotalUsers,TotalTraffic,LogType,Operator,Message,OpenVPN_ConfigData_Base64
    final header = rows.first.map((e) => e.toString().replaceAll('#', '').trim().toLowerCase()).toList();

    final hostIdx = header.indexOf('hostname');
    final ipIdx = header.indexOf('ip');
    final scoreIdx = header.indexOf('score');
    final pingIdx = header.indexOf('ping');
    final speedIdx = header.indexOf('speed');
    final countryLongIdx = header.indexOf('countrylong');
    final countryShortIdx = header.indexOf('countryshort');
    final sessionsIdx = header.indexOf('numvpnsessions');
    final configIdx = header.indexOf('openvpn_configdata_base64');

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < header.length) continue;

      try {
        final hostname = hostIdx != -1 ? row[hostIdx].toString() : '';
        final ip = ipIdx != -1 ? row[ipIdx].toString() : '';
        final score = scoreIdx != -1 ? int.tryParse(row[scoreIdx].toString()) ?? 0 : 0;
        final ping = pingIdx != -1 ? int.tryParse(row[pingIdx].toString()) ?? 0 : 0;
        final speed = speedIdx != -1 ? int.tryParse(row[speedIdx].toString()) ?? 0 : 0;
        final countryLong = countryLongIdx != -1 ? row[countryLongIdx].toString() : 'Unknown';
        final countryShort = countryShortIdx != -1 ? row[countryShortIdx].toString() : '--';
        final sessions = sessionsIdx != -1 ? int.tryParse(row[sessionsIdx].toString()) ?? 0 : 0;
        final configData = configIdx != -1 ? row[configIdx].toString() : '';

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
}

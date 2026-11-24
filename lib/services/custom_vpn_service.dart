import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/vpn_server.dart';

class CustomVpnService {
  /// Allows user to pick a .ovpn file and returns a VpnServer object
  static Future<VpnServer?> importOvpnFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ovpn'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final filePath = files.first.path!;
      final file = File(filePath);

      if (await file.exists()) {
        final content = await file.readAsString();
        final fileName = files.first.name;

        return VpnServer.fromCustomConfig(
          name: fileName,
          configText: content,
        );
      }
    }
    return null;
  }
}

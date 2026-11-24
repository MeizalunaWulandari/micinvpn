import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import '../models/vpn_server.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  denied,
}

class VpnController extends ChangeNotifier {
  late OpenVPN _openVPN;
  VpnServer? _selectedServer;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _byteIn = '0 B';
  String _byteOut = '0 B';
  String _duration = '00:00:00';
  DateTime? _connectedTime;
  Timer? _timer;

  VpnServer? get selectedServer => _selectedServer;
  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;
  bool get isConnecting => _status == ConnectionStatus.connecting;
  String get byteIn => _byteIn;
  String get byteOut => _byteOut;
  String get duration => _duration;

  void initialize({
    required VoidCallback onVpnDenied,
  }) {
    _openVPN = OpenVPN(
      onVpnStatusChanged: (data) {
        if (data != null) {
          _byteIn = data.byteIn ?? '0 B';
          _byteOut = data.byteOut ?? '0 B';
          notifyListeners();
        }
      },
      onVpnStageChanged: (stage, raw) {
        switch (stage) {
          case VPNStage.connected:
            _status = ConnectionStatus.connected;
            _startDurationTimer();
            break;
          case VPNStage.connecting:
          case VPNStage.authenticating:
          case VPNStage.reconnect:
          case VPNStage.resolve:
          case VPNStage.wait_connection:
            _status = ConnectionStatus.connecting;
            break;
          case VPNStage.disconnected:
            _status = ConnectionStatus.disconnected;
            _stopDurationTimer();
            break;
          case VPNStage.denied:
            _status = ConnectionStatus.denied;
            _stopDurationTimer();
            onVpnDenied();
            break;
          default:
            break;
        }
        notifyListeners();
      },
    );

    _openVPN.initialize(
      groupIdentifier: "group.com.micinvpn.app",
      providerBundleIdentifier: "com.micinvpn.app.VPNExtension",
      localizedDescription: "Micin VPN",
    );
  }

  void selectServer(VpnServer server) {
    _selectedServer = server;
    notifyListeners();
  }

  void toggleConnect() {
    if (_selectedServer == null) return;

    if (isConnected) {
      disconnect();
    } else {
      connect();
    }
  }

  void connect() {
    if (_selectedServer == null) return;
    final config = _selectedServer!.configContent;

    _status = ConnectionStatus.connecting;
    notifyListeners();

    _openVPN.connect(
      config,
      _selectedServer!.countryLong,
      username: 'vpn',
      password: 'vpn',
      certIsRequired: false,
    );
  }

  void disconnect() {
    _status = ConnectionStatus.disconnecting;
    notifyListeners();
    _openVPN.disconnect();
  }

  void clearSelectedServer() {
    if (isConnected || isConnecting) {
      disconnect();
    }
    _selectedServer = null;
    notifyListeners();
  }

  void _startDurationTimer() {
    _stopDurationTimer();
    _connectedTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_connectedTime == null) return;
      final diff = DateTime.now().difference(_connectedTime!);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
      _duration = '$hours:$minutes:$seconds';
      notifyListeners();
    });
  }

  void _stopDurationTimer() {
    _timer?.cancel();
    _timer = null;
    _connectedTime = null;
    _duration = '00:00:00';
    _byteIn = '0 B';
    _byteOut = '0 B';
  }

  @override
  void dispose() {
    _stopDurationTimer();
    super.dispose();
  }
}

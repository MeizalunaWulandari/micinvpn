import 'package:flutter/material.dart';
import '../controllers/vpn_controller.dart';

class ConnectedView extends StatelessWidget {
  final VpnController vpnController;
  final VoidCallback onChangeServer;

  const ConnectedView({
    super.key,
    required this.vpnController,
    required this.onChangeServer,
  });

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
      case ConnectionStatus.disconnecting:
        return Colors.orange;
      case ConnectionStatus.denied:
        return Colors.red;
      case ConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'CONNECTED';
      case ConnectionStatus.connecting:
        return 'CONNECTING...';
      case ConnectionStatus.disconnecting:
        return 'DISCONNECTING...';
      case ConnectionStatus.denied:
        return 'PERMISSION DENIED';
      case ConnectionStatus.disconnected:
        return 'DISCONNECTED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final server = vpnController.selectedServer;
    final isConnected = vpnController.isConnected;
    final isBusy = vpnController.isConnecting || vpnController.status == ConnectionStatus.disconnecting;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Connection Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(vpnController.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(vpnController.status),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.radio_button_checked,
                  color: _getStatusColor(vpnController.status),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(vpnController.status),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(vpnController.status),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Big Connect/Disconnect Button
          GestureDetector(
            onTap: isBusy ? null : vpnController.toggleConnect,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected
                    ? Colors.green
                    : (isBusy ? Colors.orange : Theme.of(context).colorScheme.primary),
                boxShadow: [
                  BoxShadow(
                    color: (isConnected ? Colors.green : Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: isBusy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(
                        Icons.power_settings_new_rounded,
                        color: Colors.white,
                        size: 72,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isConnected ? 'Tap to Disconnect' : 'Tap to Connect',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Duration and Traffic Info Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.blue),
                          const SizedBox(height: 4),
                          const Text('Duration', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            vpnController.duration,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(height: 40, width: 1, color: Colors.grey.shade300),
                      Column(
                        children: [
                          const Icon(Icons.arrow_downward, color: Colors.teal),
                          const SizedBox(height: 4),
                          const Text('Download', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            vpnController.byteIn,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(height: 40, width: 1, color: Colors.grey.shade300),
                      Column(
                        children: [
                          const Icon(Icons.arrow_upward, color: Colors.deepOrange),
                          const SizedBox(height: 4),
                          const Text('Upload', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            vpnController.byteOut,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Selected Server Details
          if (server != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    server.countryShort.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                title: Text(
                  server.countryLong,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Hostname: ${server.hostname.isNotEmpty ? server.hostname : server.ip}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: TextButton(
                  onPressed: onChangeServer,
                  child: const Text('Change'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

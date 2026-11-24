import 'package:flutter/material.dart';
import 'controllers/vpn_controller.dart';
import 'models/vpn_server.dart';
import 'services/vpn_gate_service.dart';
import 'services/custom_vpn_service.dart';
import 'views/connected_view.dart';
import 'widgets/server_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MicinVpnApp());
}

class MicinVpnApp extends StatelessWidget {
  const MicinVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Micin VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935), // Red / fiery accent
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VpnGateService _vpnGateService = VpnGateService();
  final VpnController _vpnController = VpnController();

  List<VpnServer> _servers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _vpnController.initialize(
      onVpnDenied: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('VPN permission was denied by user.'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );

    _vpnController.addListener(() {
      if (mounted) setState(() {});
    });

    _fetchServers();
  }

  Future<void> _fetchServers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final servers = await _vpnGateService.fetchServers();
      setState(() {
        _servers = servers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _importCustomConfig() async {
    try {
      final customServer = await CustomVpnService.importOvpnFile();
      if (customServer != null) {
        setState(() {
          _servers.insert(0, customServer);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported: ${customServer.hostname}'),
            backgroundColor: Colors.green,
          ),
        );

        // Auto select and switch to configured connection screen
        _vpnController.selectServer(customServer);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import config: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _vpnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedServer = _vpnController.selectedServer != null;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Micin VPN',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Import Custom .ovpn',
            icon: const Icon(Icons.file_upload_outlined, color: Colors.white),
            onPressed: _importCustomConfig,
          ),
          if (!hasSelectedServer)
            IconButton(
              tooltip: 'Refresh Servers',
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _isLoading ? null : _fetchServers,
            ),
        ],
      ),
      body: hasSelectedServer
          ? ConnectedView(
              vpnController: _vpnController,
              onChangeServer: () {
                _vpnController.clearSelectedServer();
              },
            )
          : _buildServerListView(),
    );
  }

  Widget _buildServerListView() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Fetching VPN Gate public servers...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchServers,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_servers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No VPN servers found.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchServers,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Servers (${_servers.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: _importCustomConfig,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Custom OVPN'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchServers,
            child: ListView.builder(
              itemCount: _servers.length,
              itemBuilder: (context, index) {
                final server = _servers[index];
                return ServerCard(
                  server: server,
                  onConnect: () {
                    _vpnController.selectServer(server);
                    _vpnController.connect();
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:proxy_core/constants/core_names.dart';
import 'package:proxy_core/proxy_core.dart';
import 'package:proxy_core/models/proxy_core_config.dart';

// add ignore print for the whole file
// ignore_for_file: avoid_print

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: const ProxyCoreExampleUI(),
    );
  }
}

class ProxyCoreExampleUI extends StatefulWidget {
  const ProxyCoreExampleUI({super.key});
  @override
  State<ProxyCoreExampleUI> createState() => _ProxyCoreExampleUIState();
}

class _ProxyCoreExampleUIState extends State<ProxyCoreExampleUI> {
  final ScrollController _scrollCtrl = ScrollController();
  String _logs = '';
  bool _isRunning = false;
  String? _version;
  ProxyCoreConfig? _config;
  Timer? _logTimer;

  List<CoreNames> _availableCores = [];
  CoreNames? _selectedCore;

  // Add your configs here as Map<String, dynamic>
  final Map<String, Map<String, dynamic>> _configs = {
    "Default VMess Config": {
      "dns": {
        "disableFallback": true,
        "servers": [
          {
            "address": "https://8.8.8.8/dns-query",
            "domains": [],
            "queryStrategy": ""
          },
          {"address": "localhost", "domains": [], "queryStrategy": ""}
        ],
        "tag": "dns"
      },
      "inbounds": [
        {
          "listen": "127.0.0.1",
          "port": 2080,
          "protocol": "socks",
          "settings": {"udp": true},
          "sniffing": {
            "destOverride": ["http", "tls", "quic"],
            "enabled": true,
            "metadataOnly": false,
            "routeOnly": true
          },
          "tag": "socks-in"
        }
      ],
      "log": {"loglevel": "debug"},
      "outbounds": [
        {
          "protocol": "vmess",
          "settings": {
            "vnext": [
              {
                "address": "172.67.204.84",
                "port": 443,
                "users": [
                  {
                    "id": "950db6aa-4926-4616-816e-ec0312dcb87b",
                    "alterId": 0,
                    "security": "auto"
                  }
                ]
              }
            ]
          },
          "streamSettings": {
            "network": "ws",
            "security": "tls",
            "tlsSettings": {"serverName": "jahfkjha.cfd"},
            "wsSettings": {
              "path": "/linkws",
              "headers": {"Host": "jahfkjha.cfd"}
            }
          },
          "domainStrategy": "AsIs",
          "tag": "proxy"
        },
        {"protocol": "freedom", "tag": "direct"},
        {"protocol": "freedom", "tag": "bypass"},
        {"protocol": "blackhole", "tag": "block"},
        {
          "protocol": "dns",
          "settings": {
            "address": "8.8.8.8",
            "port": 53,
            "network": "tcp",
            "userLevel": 1
          },
          "proxySettings": {"tag": "proxy", "transportLayer": true},
          "tag": "dns-out"
        }
      ],
      "policy": {
        "levels": {
          "1": {"connIdle": 30}
        },
        "system": {"statsOutboundDownlink": true, "statsOutboundUplink": true}
      },
      "routing": {
        "domainStrategy": "AsIs",
        "rules": [
          {
            "type": "field",
            "port": "53",
            "inboundTag": ["socks-in", "http-in"],
            "outboundTag": "dns-out"
          },
          {"type": "field", "port": "0-65535", "outboundTag": "proxy"}
        ]
      },
      "stats": {}
    },
    "Outline Example Config": {
      "server": "51.38.121.145",
      "server_port": 44785,
      "password": "K5RXHDq7STsVrDZEojdTqM",
      "method": "chacha20-ietf-poly1305"
    }
  };
  String _selectedConfigName = "Default VMess Config";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await ProxyCore.ins.initialize(onCoreStateChanged: (running) async {
        if (mounted) setState(() => _isRunning = running);
      });

      final localAvailableCores = CoreNames.values;

      if (mounted) {
        setState(() {
          _availableCores = localAvailableCores;
          _selectedCore = localAvailableCores.first;
        },);
      }

      if (_availableCores.isEmpty) {
        print("⚠️ No available cores (CoreNames.values is empty).");
      }
    } catch (e, st) {
      print("Example app init error: $e\n$st");
      if (mounted) {
        setState(() => _availableCores = []);
      }
    }
  }

  Future<void> _start({required bool useVpn}) async {
    try {
      final dir = (await getApplicationDocumentsDirectory()).path;
      final configMap = _configs[_selectedConfigName]!;
      final configJson = jsonEncode(configMap);
      final config = useVpn
          ? ProxyCoreConfig.inVpnMode(
              dir: dir,
              config: configJson,
              core: _selectedCore!,
            )
          : ProxyCoreConfig.inProxyMode(
              dir: dir,
              config: configJson,
              core: _selectedCore!,
            );
      await ProxyCore.ins.start(config);
      setState(() {
        _config = config;
        _logs = '';
      });
      _pollLogs();
    } catch (e) {
      print("Start error: $e");
    }
  }

  void _pollLogs() {
    _logTimer?.cancel();
    _logTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final logs = await ProxyCore.ins.fetchLogs();
        if (!mounted || logs.logs.isEmpty) return;
        setState(() => _logs += logs.logs);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          }
        });
      } catch (_) {}
    });
  }

  Future<void> _stop() async {
    try {
      _logTimer?.cancel();
      await ProxyCore.ins.stop();
      // await ProxyCore.ins.clearLogs();
      if (mounted) {
        setState(() {
          _isRunning = false;
          _logs = '';
          _config = null;
        });
      }
    } catch (e) {
      print("Stop error: $e");
    }
  }

  Future<void> _getVersion() async {
    try {
      final v = await ProxyCore.ins.version;
      setState(() => _version = v);
    } catch (e) {
      print("Version error: $e");
    }
  }

  Future<void> _ping() async {
    try {
      final res = await ProxyCore.ins.measurePing([
        "https://google.com/generate_204",
        "https://gstatic.com/generate_204"
      ]);
      print("Ping: $res");
    } catch (e) {
      print("Ping error: $e");
    }
  }

  void _clearLogs() => setState(() => _logs = '');

  @override
  void dispose() {
    _logTimer?.cancel();
    _scrollCtrl.dispose();
    ProxyCore.ins.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Proxy Core UI")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status: ${_isRunning ? 'Running' : 'Stopped'}",
                style: Theme.of(context).textTheme.titleMedium),
            Text("Version: ${_version ?? 'Unknown'}",
                style: Theme.of(context).textTheme.titleMedium),
            if (_config != null)
              Text("Core: ${_config!.core.name}",
                  style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // Core selection dropdown
            DropdownButton<CoreNames>(
              value: _selectedCore,
              hint: const Text("Select Core"),
              isExpanded: true,
              onChanged: (val) => setState(() => _selectedCore = val),
              items: _availableCores
                  .map((core) => DropdownMenuItem(
                        value: core,
                        child: Text(core.name),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Config selection radio buttons
            Text("Choose Config:",
                style: Theme.of(context).textTheme.titleMedium),
            ..._configs.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.key),
                value: entry.key,
                groupValue: _selectedConfigName,
                onChanged: (val) => setState(() {
                  _selectedConfigName = val!;
                }),
                contentPadding: EdgeInsets.zero,
              );
            }),

            const SizedBox(height: 16),

            // Buttons wrapped for responsive layout
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : () => _start(useVpn: false),
                  child: const Text("Start Proxy"),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : () => _start(useVpn: true),
                  child: const Text("Start VPN"),
                ),
                ElevatedButton(
                  onPressed: _ping,
                  child: const Text("Ping"),
                ),
                ElevatedButton(
                  onPressed: _getVersion,
                  child: const Text("Get Version"),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? _stop : null,
                  child: const Text("Stop"),
                ),
                ElevatedButton(
                  onPressed: _clearLogs,
                  child: const Text("Clear Logs"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  child: Text(
                    _logs.isEmpty ? 'No logs yet' : _logs,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

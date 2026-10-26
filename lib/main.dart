import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_walkie_talkie/flutter_local_walkie_talkie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(const PreparadoRadioApp());
}

class PreparadoRadioApp extends StatelessWidget {
  const PreparadoRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preparado Rádio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFC107),
          secondary: Color(0xFFFFC107),
        ),
        useMaterial3: true,
      ),
      home: const RadioHomePage(),
    );
  }
}

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({super.key});

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> {
  final WalkieTalkie _walkieTalkie = WalkieTalkie();
  List<WalkieTalkieDevice> _devices = [];
  WalkieTalkieDevice? _connectedDevice;
  bool _isTalking = false;
  String _status = 'Iniciando...';
  String _deviceName = 'Rádio';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. Pedir permissões apenas se NÃO for Web
      if (!kIsWeb) {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.microphone,
          Permission.location,
          Permission.nearbyWifiDevices,
        ].request();

        if (!statuses[Permission.microphone]!.isGranted) {
          setState(() => _status = 'Permissão de microfone negada');
          return;
        }
      }

      // 2. Descobrir nome do aparelho
      if (!kIsWeb && Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        _deviceName = androidInfo.model;
      }

      // 3. Inicializar o WalkieTalkie
      await _walkieTalkie.init(deviceName: _deviceName);
      _walkieTalkie.startSearching();

      // 4. Escutar dispositivos descobertos
      _walkieTalkie.discoveredDevices.listen((devices) {
        if (mounted) {
          setState(() {
            _devices = devices;
            if (_connectedDevice == null) {
              _status = devices.isEmpty
                  ? 'Buscando rádios...'
                  : '${devices.length} rádio(s) encontrado(s)';
            }
          });
        }
      });

      if (mounted) setState(() => _status = 'Pronto');
    } catch (e) {
      if (mounted) setState(() => _status = 'Erro: $e');
    }
  }

  void _connect(WalkieTalkieDevice device) {
    _walkieTalkie.connectToDevice(device);
    setState(() {
      _connectedDevice = device;
      _status = 'Conectado a ${device.name}';
    });
  }

  Future<void> _startTalking() async {
    if (_connectedDevice == null) return;
    setState(() => _isTalking = true);
    await _walkieTalkie.startTalking();
  }

  Future<void> _stopTalking() async {
    setState(() => _isTalking = false);
    await _walkieTalkie.stopTalking();
  }

  @override
  void dispose() {
    _walkieTalkie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Image.asset(
                'assets/logoprep.png',
                height: 80,
              ),
            ),
            Text(
              _status,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),

            if (_connectedDevice == null)
              Expanded(
                child: _devices.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum rádio encontrado.\nVerifique se ambos estão na mesma rede Wi-Fi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          return ListTile(
                            leading: const Icon(Icons.radio, color: Color(0xFFFFC107)),
                            title: Text(device.name,
                                style: const TextStyle(color: Colors.white)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () => _connect(device),
                              child: const Text('Conectar'),
                            ),
                          );
                        },
                      ),
              )
            else
              const Spacer(),

            if (_connectedDevice != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: GestureDetector(
                  onTapDown: (_) => _startTalking(),
                  onTapUp: (_) => _stopTalking(),
                  onTapCancel: _stopTalking,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isTalking
                          ? const Color(0xFFFFC107)
                          : const Color(0xFF222222),
                      border: Border.all(
                        color: const Color(0xFFFFC107),
                        width: 4,
                      ),
                      boxShadow: _isTalking
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFFC107).withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Icon(
                        _isTalking ? Icons.mic : Icons.mic_none,
                        size: 60,
                        color: _isTalking ? Colors.black : const Color(0xFFFFC107),
                      ),
                    ),
                  ),
                ),
              ),
            if (_connectedDevice != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _connectedDevice = null;
                      _status = 'Desconectado';
                      _walkieTalkie.startSearching();
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.white38),
                  label: const Text('Desconectar',
                      style: TextStyle(color: Colors.white38)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

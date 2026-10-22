import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const BastonApp());
}

class BastonApp extends StatelessWidget {
  const BastonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bastón Inteligente',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Configuración MQTT (Ajusta la IP por la de tu broker o ESP32)
  final client = MqttServerClient('192.168.1.100', 'flutter_client');
  String estadoConexion = 'Desconectado';
  String mensajeAlerta = 'Sin alertas';

  @override
  void initState() {
    super.initState();
    _conectarMQTT();
  }

  Future<void> _conectarMQTT() async {
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } catch (e) {
      setState(() {
        estadoConexion = 'Error de conexión';
      });
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      setState(() {
        estadoConexion = 'Conectado al ESP32';
      });
      
      // Suscribirse al topic del sensor ultrasónico
      const topic = 'baston/alertas';
      client.subscribe(topic, MqttQos.atMostOnce);
      
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final recMess = c![0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        setState(() {
          mensajeAlerta = pt;
        });
      });
    }
  }

  void _onConnected() {
    print('Conectado exitosamente');
  }

  void _onDisconnected() {
    setState(() {
      estadoConexion = 'Desconectado';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard - Bastón IA', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                estadoConexion == 'Conectado al ESP32' ? Icons.wifi : Icons.wifi_off,
                size: 80,
                color: estadoConexion == 'Conectado al ESP32' ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                estadoConexion,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: mensajeAlerta.contains('Obstáculo') ? Colors.red.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Estado del Sensor:',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      mensajeAlerta,
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: mensajeAlerta.contains('Obstáculo') ? Colors.red : Colors.black
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
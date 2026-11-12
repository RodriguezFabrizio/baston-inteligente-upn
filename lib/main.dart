import 'dart:convert';

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
      title: 'Monitoreo Bastón Inteligente',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MonitorScreen(),
    );
  }
}

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  // Cliente MQTT
  late MqttServerClient client;
  String connectionStatus = "Desconectado";
  int distanciaActual = 0;
  bool alertaActiva = false;
  String dispositivo = "Esperando datos...";

  @override
  void initState() {
    super.initState();
    _conectarMQTT();
  }

  Future<void> _conectarMQTT() async {
    // ID de cliente único aleatorio
    client = MqttServerClient(
      'test.mosquitto.org',
      'FlutterCaregiverApp_${DateTime.now().millisecondsSinceEpoch}',
    );
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;

    final MqttConnectMessage connMess =
        MqttConnectMessage().withClientIdentifier('FlutterClient').startClean();
    client.connectionMessage = connMess;

    try {
      setState(() {
        connectionStatus = "Conectando al broker...";
      });
      await client.connect();
    } catch (e) {
      print('Excepción de conexión: $e');
      client.disconnect();
      setState(() {
        connectionStatus = "Error de conexión";
      });
      return;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      setState(() {
        connectionStatus = "Conectado al Bastón";
      });
      print('MQTT Conectado');

      const topic = 'baston/alerta';
      client.subscribe(topic, MqttQos.atMostOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> c) {
        final MqttPublishMessage recMessage =
            c[0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToString(
          recMessage.payload.message,
        );

        print('Mensaje recibido: $payload');

        // Parsear JSON recibido del ESP32 DevKit
        try {
          final data = jsonDecode(payload);
          setState(() {
            dispositivo = data['dispositivo'] ?? 'ESP32_DevKit';
            distanciaActual = data['distancia_cm'] ?? 0;
            alertaActiva = data['alerta'] ?? false;
          });
        } catch (e) {
          print("Error al parsear JSON: $e");
        }
      });
    } else {
      setState(() {
        connectionStatus =
            "Fallo la conexión (Estado: ${client.connectionStatus!.state})";
      });
      client.disconnect();
    }
  }

  void _onDisconnected() {
    setState(() {
      connectionStatus = "Desconectado del servidor";
    });
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Color de fondo cambia dinámicamente si hay peligro
    Color backgroundColor =
        alertaActiva ? Colors.red.shade100 : Colors.green.shade50;
    Color cardColor = alertaActiva ? Colors.red.shade400 : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuidador - Bastón Inteligente'),
        backgroundColor: alertaActiva ? Colors.red : Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: backgroundColor,
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Estado de la conexión
            Chip(label: Text(connectionStatus), backgroundColor: Colors.white),
            const SizedBox(height: 30),

            // Dispositivo
            Text(
              dispositivo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta principal de distancia
            Card(
              elevation: 6,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 30,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Distancia del Obstáculo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '$distanciaActual cm',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color:
                            alertaActiva ? Colors.white : Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Indicador de Alerta Visual Grande
            if (alertaActiva)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(width: 10),
                    Text(
                      '¡PELIGRO: OBSTÁCULO CERCA!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'CAMINO DESPEJADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

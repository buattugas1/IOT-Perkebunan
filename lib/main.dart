import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoring PLTS MQTT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: MonitoringPage(),
    );
  }
}

class MonitoringPage extends StatefulWidget {
  @override
  _MonitoringPageState createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  late MqttBrowserClient client;
  final String broker = 'ws://192.168.0.112:9001'; // Alamat broker via WebSocket
  final String topic = 'plts/status';

  double lux = 0.0;
  String gerakan = 'Tidak';
  int pwm = 0;
  String statusKoneksi = 'Menghubungkan...';

  @override
  void initState() {
    super.initState();
    connectToMqtt();
  }

  Future<void> connectToMqtt() async {
    client = MqttBrowserClient(broker, 'flutter_web_client_${DateTime.now().millisecondsSinceEpoch}');
    client.port = 9001;
    client.keepAlivePeriod = 20;
    client.logging(on: true);
    client.setProtocolV311();

    client.onConnected = () {
      print('Connected');
      setState(() => statusKoneksi = 'Tersambung');
    };

    client.onDisconnected = () {
      print('Disconnected');
      setState(() => statusKoneksi = 'Terputus');
    };

    client.onSubscribed = (t) => print('Subscribed to $t');

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_web_client_${DateTime.now().millisecondsSinceEpoch}')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMess;

    try {
      await client.connect();
    } catch (e) {
      print('Connection failed: $e');
      setState(() => statusKoneksi = 'Gagal koneksi');
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('Connected to broker');
      client.subscribe(topic, MqttQos.atMostOnce);

      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> events) {
        final MqttPublishMessage recMess = events[0].payload as MqttPublishMessage;
        final String message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print('Received: $message');

        try {
          final jsonData = json.decode(message);
          setState(() {
            lux = (jsonData['lux'] ?? 0).toDouble();
            gerakan = jsonData['gerakan'] ?? 'Tidak';
            pwm = jsonData['pwm'] ?? 0;
          });
        } catch (e) {
          print('JSON error: $e');
        }
      });
    } else {
      print('Failed to connect: ${client.connectionStatus?.state}');
      setState(() => statusKoneksi = 'Gagal koneksi');
    }
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Monitoring PLTS MQTT')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Status Koneksi: $statusKoneksi", style: TextStyle(fontSize: 18, color: Colors.blue)),
            SizedBox(height: 20),
            Text("Intensitas Cahaya (Lux): ${lux.toStringAsFixed(2)}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Status Gerakan: $gerakan", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Nilai PWM: $pwm", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'constants.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? _client;
  final Map<String, StreamController<bool>> _statusControllers = {};

  Future<void> _ensureConnected() async {
    if (_client != null && _client!.connectionStatus?.state == MqttConnectionState.connected) {
      return;
    }

    final clientId = 'greenhouse_app_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(MqttConfig.host, clientId, MqttConfig.port);
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 20;
    _client!.autoReconnect = true;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();
    _client!.connectionMessage = connMessage;

    try {
      print('MQTT: Connecting to ${MqttConfig.host}:${MqttConfig.port}...');
      await _client!.connect();
      print('MQTT: Connected successfully.');
      
      _client!.updates?.listen(_onMessage);
    } catch (e) {
      print('MQTT: Connection failed - $e');
      try {
        _client!.disconnect();
      } catch (_) {}
    }
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final MqttPublishMessage recMess = message.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if (topic.endsWith('/status')) {
        try {
          final data = json.decode(payload) as Map<String, dynamic>;
          final isOnline = data['online'] as bool;
          final controller = _statusControllers[topic];
          if (controller != null && !controller.isClosed) {
            controller.add(isOnline);
          }
        } catch (e) {
          print('MQTT: Error parsing status payload from $topic: $e');
        }
      }
    }
  }

  static Future<void> publishGreenhouses(Map<String, List<String>> map) async {
    final service = MqttService();
    await service._ensureConnected();
    if (service._client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(json.encode(map));
      service._client!.publishMessage(MqttConfig.topic, MqttQos.atLeastOnce, builder.payload!);
      print('MQTT: Published update to ${MqttConfig.topic}');
      // allow short time for publish to complete
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Stream<bool> subscribeToStatus(String greenhouseId, String deviceId) {
    final topic = '$greenhouseId/$deviceId/status';
    final controller = _statusControllers.putIfAbsent(topic, () => StreamController<bool>.broadcast());
    
    _ensureConnected().then((_) {
      if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
        _client!.subscribe(topic, MqttQos.atLeastOnce);
        print('MQTT: Subscribed to $topic');
      }
    });

    return controller.stream;
  }
}

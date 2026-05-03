import 'dart:async';
import 'package:flutter/services.dart';

class ThreatMonitorService {
  static const EventChannel _eventChannel = EventChannel('com.mindquest/security_events');
  StreamSubscription? _subscription;
  final _threatStreamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get threatStream => _threatStreamController.stream;

  void startMonitoring() {
    _subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final data = Map<String, dynamic>.from(event);
        print("🚨 Security Alert: ${data['type']}");
        _threatStreamController.add(data);
      }
    });
  }

  void stopMonitoring() => _subscription?.cancel();
}
import 'dart:convert';
import 'package:flutter/services.dart';

class VpnController {
  static const MethodChannel _channel = MethodChannel('com.mindquest/vpn');

  static Future<bool> startVpn(List<String> blockedDomains) async {
    try {
      final String jsonDomains = jsonEncode(blockedDomains);
      final bool result = await _channel.invokeMethod('startVpn', {
        'blockedDomains': jsonDomains,
      });
      return result;
    } on PlatformException catch (e) {
      return false;
    }
  }

  static Future<bool> stopVpn() async {
    final bool result = await _channel.invokeMethod('stopVpn');
    return result;
  }
}
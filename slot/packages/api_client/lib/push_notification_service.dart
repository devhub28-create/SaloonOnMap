import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'firebase_runtime.dart';

class PushNotificationService {
  PushNotificationService({required this.apiClient, required this.appType});

  final ApiClient apiClient;
  final String appType;
  StreamSubscription<String>? _refreshSubscription;
  String? _registeredToken;

  bool get isConfigured => FirebaseRuntime.isConfigured;

  Future<bool> register() async {
    if (!isConfigured || kIsWeb) return false;
    try {
      if (!await FirebaseRuntime.initialize()) return false;
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return false;
      await _registerToken(token);
      await _refreshSubscription?.cancel();
      _refreshSubscription = messaging.onTokenRefresh.listen(
        _registerToken,
        onError: (_) {},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _registerToken(String token) async {
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => 'IOS',
      _ => 'ANDROID',
    };
    await apiClient.registerDevice(
      token: token,
      platform: platform,
      appType: appType,
    );
    _registeredToken = token;
  }

  Future<void> unregister() async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
    final token = _registeredToken;
    _registeredToken = null;
    if (token != null) {
      try {
        await apiClient.unregisterDevice(token);
      } catch (_) {}
    }
  }
}

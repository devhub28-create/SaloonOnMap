import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_runtime.dart';

class FirebaseObservabilityService {
  static Future<bool> initialize({required String appType}) async {
    if (!await FirebaseRuntime.initialize()) return false;
    final enabled = kReleaseMode;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(enabled);
      if (!enabled) return true;

      await FirebaseAnalytics.instance.setUserProperty(
        name: 'app_type',
        value: appType.toLowerCase(),
      );
      await FirebaseAnalytics.instance.logAppOpen();

      final previousFlutterHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        previousFlutterHandler?.call(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      return true;
    } catch (_) {
      return false;
    }
  }
}

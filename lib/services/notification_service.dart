import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _token;
  RemoteMessage? _lastMessage;

  String? get token => _token;
  RemoteMessage? get lastMessage => _lastMessage;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) debugPrint('[Notification] Permission denied');
      return;
    }

    _token = await _messaging.getToken();
    if (kDebugMode) debugPrint('[Notification] Token: $_token');

    _messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      notifyListeners();
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[Notification] Foreground: ${message.notification?.title}');
    }
    _lastMessage = message;
    notifyListeners();
  }

  Future<void> saveTokenToFirestore(String barbeariaId, String usuarioDocId) async {
    if (_token == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colBarbearias)
          .doc(barbeariaId)
          .collection(AppConstants.colUsuarios)
          .doc(usuarioDocId)
          .set({'fcmToken': _token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
              SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] Error saving token: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) debugPrint('[Notification] Subscribed to $topic');
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] Subscribe error: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) debugPrint('[Notification] Unsubscribed from $topic');
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] Unsubscribe error: $e');
    }
  }
}

// ignore_for_file: empty_catches

import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/config.dart';
import '../../services/data_store.dart';
import '../../utils/common_widget.dart';
import '../workspace.dart';
import '../../services/http.dart';
 
late AndroidNotificationChannel channel;
bool isFlutterLocalNotificationsInitialized = false;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
bool _isFcmRefreshListenerAttached = false;
String? _runtimeLastSyncedFcmToken;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotificationfromFirebase(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null && !kIsWeb) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'launch_background',
        ),
      ),
    );
  }
}

Future<void> setupPushNotifications() async {
  await FirebaseMessaging.instance.requestPermission();
  await setupFlutterNotifications();
  await getFCMTokenInitialToSetThedata(forceSync: true);
  _attachFcmTokenRefreshListener();
}

void _attachFcmTokenRefreshListener() {
  if (_isFcmRefreshListenerAttached) {
    return;
  }
  _isFcmRefreshListenerAttached = true;
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint(
        "[PushDebug] onTokenRefresh received | tokenPreview=${newToken.substring(0, newToken.length > 16 ? 16 : newToken.length)}...");
    await _updateFcmTokenOnServer(
      newToken,
      trigger: "onTokenRefresh",
      forceSync: true,
    );
  });
}

Future<void> getFCMTokenInitialToSetThedata({bool forceSync = false}) async {
  try {
    var fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await _updateFcmTokenOnServer(
        fcmToken,
        trigger: "init",
        forceSync: forceSync,
      );
    }
  } catch (error) {
    //
  }
}

Future<void> getFCMToken({bool forceSync = false}) async {
  try {
    var fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await _updateFcmTokenOnServer(
        fcmToken,
        trigger: "refresh",
        forceSync: forceSync,
      );
    }
  } catch (error) {}
}

Future<void> syncPendingFcmTokenIfAny({bool forceSync = true}) async {
  try {
    String pendingToken = box.get("pendingFcmToken")?.toString() ?? "";
    if (pendingToken.isNotEmpty) {
      await _updateFcmTokenOnServer(
        pendingToken,
        trigger: "pending_sync",
        forceSync: forceSync,
      );
      return;
    }

    await getFCMToken(forceSync: forceSync);
  } catch (e) {
    debugPrint("[PushDebug] syncPendingFcmTokenIfAny failed | error=$e");
  }
}

Future<void> _updateFcmTokenOnServer(
  String fcmToken, {
  String trigger = "",
  bool forceSync = false,
}) async {
  try {
    if (token.isEmpty) {
      box.put("pendingFcmToken", fcmToken);
      debugPrint(
          "[PushDebug] fcmUpdate delayed (user token missing) | trigger=$trigger");
      return;
    }

    if (!forceSync && _runtimeLastSyncedFcmToken == fcmToken) {
      debugPrint(
          "[PushDebug] fcmUpdate skipped (already synced this session) | trigger=$trigger");
      return;
    }

    await httpPost(
      Config.fcmUpdate,
      {"fcm": fcmToken},
      context: navigatorKey.currentContext!,
    );
    _runtimeLastSyncedFcmToken = fcmToken;
    box.put("lastSyncedFcmToken", fcmToken);
    box.delete("pendingFcmToken");
    debugPrint("[PushDebug] fcmUpdate success | trigger=$trigger");
  } catch (e) {
    box.put("pendingFcmToken", fcmToken);
    debugPrint("[PushDebug] fcmUpdate failed | trigger=$trigger | error=$e");
  }
}

Future<void> showNotification(context) async {
  FirebaseMessaging.onMessage.listen((RemoteMessage event) async {
    showFlutterNotificationfromFirebase(event);
  });
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
  await setupFlutterNotifications();
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    handleNotificationClick(initialMessage.data['route'], initialMessage.data);
  }
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage event) {
    if (event.data.isNotEmpty) {
      handleNotificationClick(event.data['route'], event.data);
    }
  });
}

void handleNotificationClick(String? route, var data) {
  if (token.isEmpty) {
    showErrorToastMessage("Please Login first");

    return;
  }
  if (route != null) {

    // userEnd notification routing================
  }
}

Future<void> initializeNotifications() async {
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('launch_background');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      if (notificationResponse.payload != null) {
        try {
          final Map<String, dynamic> data =
              jsonDecode(notificationResponse.payload!);
          handleNotificationClick(data["route"], data);
        } catch (e) {}
      }
    },
  );
}

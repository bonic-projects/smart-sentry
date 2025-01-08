import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:smart_sentry/app/app.bottomsheets.dart';
import 'package:smart_sentry/app/app.dialogs.dart';
import 'package:smart_sentry/app/app.locator.dart';
import 'package:stacked_services/stacked_services.dart';

import 'app/app.router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background notifications here
  print("Handling a background message: ${message.messageId}");
  // You can add more background handling logic if needed
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();
  if (Firebase.apps.isEmpty) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await Firebase.initializeApp();
  }

  // Initialize other necessary components
  await setupLocator();
  setupDialogUi();
  setupBottomSheetUi();

  // Initialize Firebase messaging listeners
  PushNotificationService().init();

  // Start the app
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.startupView,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [
        StackedService.routeObserver,
      ],
    );
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService _instance = PushNotificationService._();

  factory PushNotificationService() => _instance;

  void init() {
    // Foreground notification listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // You can display a custom notification UI or print it for debugging
        print('Notification: ${message.notification!.title}');
        print('Body: ${message.notification!.body}');
      }
    });

    // When the user taps on a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data; // Access notification payload
      navigatorKey.currentState?.pushNamed(
        '/notificationView',
        arguments: {
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'snapshotUrl': data['snapshotUrl'],
        },
      );
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/auth_service.dart';
import 'package:smart_sentry/models/appuser.dart';

class RegisterViewModel extends BaseViewModel {
  final _userService = locator<UserService>();
  final _navigationService = locator<NavigationService>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> registerUser() async {
    setBusy(true);
    try {
      UserModel user = UserModel(
        id: '',
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
      );
      // UserCredential userCredential = await _userService.registerUser(user);
      // user.id = userCredential.user?.uid ?? '';
      final userCredential = await _userService.registerUser(user);

      // Set the user id from the userCredential.uid
      user.id = userCredential.user?.uid ?? '';
      await requestNotificationPermissions();
      _navigationService.replaceWithLoginView();
    } catch (e) {
      // Handle error
      print(e);
    } finally {
      setBusy(false);
    }
  }

  Future<void> requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications.');
      await saveFcmTokenToFirestore(); // Save FCM token after permission is granted
    } else {
      print('User declined or has not granted permission.');
    }
  }

  // Save the FCM token to Firestore
  Future<void> saveFcmTokenToFirestore() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? fcmToken = await messaging.getToken();

      if (fcmToken != null) {
        final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set({'fcmToken': fcmToken}, SetOptions(merge: true));
          print('FCM token saved successfully.');
        } else {
          print('No user ID available. Unable to save FCM token.');
        }
      } else {
        print('Failed to retrieve FCM token.');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:smart_sentry/services/firebase_service.dart';
import 'package:stacked/stacked.dart';
import '../../../models/locatio_model.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationViewModel extends BaseViewModel {
  final FirebaseService _firebaseService = FirebaseService();
  LocationData? locationData;
  List<Map<String, dynamic>> notifications = [];

  NotificationViewModel() {
    _initializeFCM();
  }

  // Initialize FCM token (check existing token or retrieve new one)
  Future<void> _initializeFCM() async {
    setBusy(true);
    await _firebaseService.initializeFCM();
    await fetchNotifications();
    setBusy(false);
  }

  // Fetch notifications from Firestore
  Future<void> fetchNotifications() async {
    setBusy(true); // Start loading

    try {
      notifications = await _firebaseService.fetchNotifications();
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      setBusy(false); // Stop loading
    }
  }

  // Open Google Maps with location data
  Future<void> openMap(BuildContext context) async {
    if (locationData?.latitude != null && locationData?.longitude != null) {
      final Uri url = Uri.parse(
          "https://www.google.com/maps/dir/?api=1&destination=${locationData!.latitude},${locationData!.longitude}");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the map.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location data not available.')),
      );
    }
  }
}

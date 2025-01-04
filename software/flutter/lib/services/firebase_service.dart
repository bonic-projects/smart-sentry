import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initializeFCM() async {
    try {
      await _messaging.requestPermission();

      // Retrieve the current FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        // Save or update the token in Firestore if needed
        await _updateFCMToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        await _updateFCMToken(newToken);
      });

      print('FCM initialization complete');
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  Future<void> _updateFCMToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
        });
        print('FCM token updated successfully in Firestore');
      }
    } catch (e) {
      print('Error updating FCM token in Firestore: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        final contactsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .get();

        // Filter out the data for the sender
        List<Map<String, dynamic>> notifications = contactsSnapshot.docs
            .where((doc) => doc.id != userId) // Exclude sender's own data
            .map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'snapshotUrl': data['snapshotUrl'] ?? '',
          };
        }).toList();

        return notifications;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }
}

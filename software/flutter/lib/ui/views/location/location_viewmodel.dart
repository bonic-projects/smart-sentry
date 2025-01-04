import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
import 'package:stacked/stacked.dart';
import 'package:flutter/material.dart';
import 'package:smart_sentry/services/location_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class LocationViewModel extends BaseViewModel {
  final LocationService _locationService = LocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? ipAddress;
  String? contactId;
  double? latitude;
  double? longitude;
  Uint8List? snapshot;
  TextEditingController ipController = TextEditingController();
  StreamSubscription? _buttonStatusSubscription;

  String? get snapshotUrl {
    if (ipAddress != null && ipAddress!.isNotEmpty) {
      return 'http://$ipAddress/snapshot';
    }
    return null;
  }
  Future<void> init() async {
    await loadSavedIPAddress(); // Load the saved IP address on initialization
  }

  Future<void> loadSavedIPAddress() async {
    try {
      final savedIP = await _locationService.getIPAddress();
      if (savedIP != null) {
        ipAddress = savedIP;
        ipController.text = savedIP; // Set TextEditingController's text
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved IP address: $e');
    }
  }

  Future<void> saveIPAddress(String ip) async {
    await _locationService.saveIPAddress(ip);
    ipAddress = ip;
    ipController.text = ip; // Update TextEditingController
    notifyListeners();
  }
  /// Fetch location data and start listening for updates
  Future<void> startListening(String ip) async {
    setBusy(true);
    ipAddress = ip;
    try {
      // Save the new IP address
      await saveIPAddress(ip);

      // Fetch current location
      final position = await _locationService.getCurrentLocation();
      latitude = position.latitude;
      longitude = position.longitude;

      // Start checking button status continuously
      _buttonStatusSubscription = Stream.periodic(Duration(seconds: 1))
          .asyncMap((_) => _locationService.checkButtonStatus(ipAddress!))
          .listen((isPressed) async {
        print('Button status: $isPressed');
        if (isPressed) {
          // If the button is pressed, fetch the snapshot
          snapshot = await _locationService.fetchSnapshot(ipAddress!);
          print('New snapshot fetched!');
          notifyListeners();

          if (snapshot != null) {
            await saveSnapshotLocally(snapshot!); // Save snapshot locally
            print('Snapshot saved locally');
            final snapshotUrl =
            await _uploadSnapshot(snapshot!); // Simulate upload

            // Fetch the logged-in user's emergency contacts
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId == null) {
              print('No user is logged in');
              return;
            }

            // Fetch the user's emergency contacts from Firestore
            final emergencyContactsSnapshot = await _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('emergencyContacts')
                .get();

            // Loop through the emergency contacts and notify the added ones
            for (var contactDoc in emergencyContactsSnapshot.docs) {
              final contactId = contactDoc.id; // Assuming contactId is stored

              // Store latitude, longitude, and snapshot URL in Firestore
              final contactData = {
                'latitude': latitude,
                'longitude': longitude,
                'snapshotUrl': snapshotUrl,
                'timestamp': FieldValue.serverTimestamp(),
              };

              await _firestore
                  .collection('users')
                  .doc(currentUserId)
                  .collection('emergencyContacts')
                  .doc(contactId)
                  .set(contactData)
                  .catchError((e) {
                print('Error updating contact data: $e');
              });

              // Send the emergency data to the added contact
              await sendEmergencyData(
                contactId: contactId,
                latitude: latitude!,
                longitude: longitude!,
                snapshotUrl: snapshotUrl,
              );
            }

            notifyListeners();
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
    setBusy(false);
  }

  @override
  void dispose() {
    _buttonStatusSubscription?.cancel();
    ipController.dispose(); // Dispose the controller when not needed
    super.dispose();
  }

  /// Method to send emergency data and notify users via Firestore and FCM
  Future<void> sendEmergencyData({
    required String contactId,
    required double latitude,
    required double longitude,
    required String snapshotUrl,
  }) async {
    try {
      // Get the currently logged-in user
      final loggedInUser = _auth.currentUser;

      if (loggedInUser == null) {
        print('No logged-in user found');
        return;
      }

      print('Snapshot URL: $snapshotUrl');

      // Retrieve the user's emergency contacts subcollection
      try {
        final emergencyContactsSnapshot = await _firestore
            .collection('users')
            .doc(loggedInUser.uid)
            .collection('emergencyContacts') // Subcollection name
            .get();

        if (emergencyContactsSnapshot.docs.isEmpty) {
          print('No emergency contacts found for user ID: ${loggedInUser.uid}');
          return;
        }

        // Extract contact IDs from the documents
        List<String> emergencyContacts = emergencyContactsSnapshot.docs
            .map((doc) => doc.id) // Assuming contact IDs are the document IDs
            .toList();

        print('Emergency contacts: $emergencyContacts');

        // Check if the contactId exists in the user's emergency contacts
        if (emergencyContacts.contains(contactId)) {
          print('Sending data to contact: $contactId');

          // Send emergency data to the specified contact
        }
      }
      catch(e){

      }
    }catch(e){}
    }
  /// Fetch list of logged-in users from Firestore
  Future<List<Map<String, dynamic>>> getLoggedInUsers() async {
    final querySnapshot = await _firestore.collection('users').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Upload snapshot to Firebase Storage
  Future<String> _uploadSnapshot(Uint8List snapshotData) async {
    try {
      // Create a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('snapshots')
          .child('snapshot_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the snapshot data
      final uploadTask = await storageRef.putData(snapshotData);

      // Get the download URL of the uploaded file
      final snapshotUrl = await storageRef.getDownloadURL();

      print('Snapshot uploaded successfully. URL: $snapshotUrl');
      return snapshotUrl;
    } catch (e) {
      print('Error uploading snapshot: $e');
      throw Exception('Snapshot upload failed');
    }
  }

  /// Save snapshot locally for future use
  Future<void> saveSnapshotLocally(Uint8List snapshotData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/snapshot_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(snapshotData);
    } catch (e) {
      print('Error saving snapshot locally: $e');
    }
  }
}
  
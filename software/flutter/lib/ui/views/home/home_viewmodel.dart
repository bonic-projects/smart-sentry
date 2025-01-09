import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_sentry/app/app.locator.dart';
import 'package:smart_sentry/app/app.router.dart';
import 'package:smart_sentry/services/location_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:smart_sentry/models/appuser.dart';

import '../../../app/app.bottomsheets.dart';
import '../../../services/auth_service.dart';
import '../../common/app_strings.dart';

class HomeViewModel extends ReactiveViewModel {
  final _bottomSheetService = locator<BottomSheetService>();
  final _snackbarService = locator<SnackbarService>();
  final _userService = locator<UserService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final LocationService _locationService = LocationService();
  final _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserModel> _searchResults = [];
  List<UserModel> get searchResults => _searchResults;
  List<String> _emergencyContactIds = [];
  UserModel loggedInUser;
  String userName = 'Loading...';
  HomeViewModel(this.loggedInUser);

  String get currentUserId => _auth.currentUser?.uid ?? '';
  bool isLocationEnabled = false;
  String? message = '';
  bool hasNewNotification = false;

  // List<Map<String, dynamic>> users = [];
  // List<Map<String, dynamic>> filteredUsers = [];
  // String searchQuery = '';

  List<Map<String, dynamic>> notifications = [];


  Future<void> fetchUserName() async {
    setBusy(true); // Show loading indicator

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        userName = 'Unknown User'; // Handle null case
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        userName = data['name'] ?? 'Unknown User';
      } else {
        userName = 'User not found';
      }
    } catch (e) {
      userName = 'Error fetching name';
    } finally {
      setBusy(false); // Hide loading indicator
      notifyListeners(); // Notify UI to rebuild
    }
  }
  void listenToNotifications() {
    final userId = _auth.currentUser?.uid;

    if (userId != null) {
      _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        notifications = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
        Future.delayed(Duration(seconds: 5), () {
          hasNewNotification = true;
        });
        notifyListeners();
      });
    }
  }

  // Mark notification as read (if needed)
  Future<void> markNotificationAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;

    if (userId != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    }
  }

  Future<void> initializeLocationService() async {
    setBusy(true);

    try {
      // Attempt to initialize the location service
      bool isLocationInitialized =
          await _locationService.initializeLocationService();

      if (isLocationInitialized) {
        _snackbarService.showSnackbar(
          message: 'Location permission granted.',
        );

        // Optionally, get the current location
        var currentPosition = await _locationService.getCurrentLocation();
        print('Current position: $currentPosition');
      } else {
        _snackbarService.showSnackbar(
          message: 'Location services are disabled or permission is denied.',
        );
      }
    } catch (e) {
      _snackbarService.showSnackbar(
        message: 'An error occurred: ${e.toString()}',
      );
    } finally {
      setBusy(false);
    }
  }

  Future<void> logout() async {
    // Show confirmation dialog before logging out
    DialogResponse? response = await _dialogService.showConfirmationDialog(
      title: 'Logout',
      description: 'Are you sure you want to logout?',
      confirmationTitle: 'Yes',
      cancelTitle: 'No',
    );

    if (response != null && response.confirmed) {
      setBusy(true); // Indicate that the process is busy
      try {
        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();

        // Ensure Firestore operations are not performed after logging out
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          // If the user is null, log out was successful
          print("User is logged out");
        }

        // Optionally, navigate to the login view
        _navigationService.clearStackAndShow(Routes.loginView);

        setBusy(false); // Reset busy state
      } catch (error) {
        // Handle any errors during logout
        setBusy(false);
        print('Error during logout: $error');
      }
    }
  }


  Future<void> loadEmergencyContacts(String currentUserId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users') // Reference to users collection
        .doc(currentUserId) // Use the current user ID
        .collection(
            'emergencyContacts') // Access the emergencyContacts sub-collection
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Extract contact IDs from the documents in the emergencyContacts sub-collection
      _emergencyContactIds = snapshot.docs.map((doc) => doc.id).toList();
    }
    _updateSearchResults();
    notifyListeners(); // Update UI after loading contacts
  }

  // Method to update the isEmergencyContact flag for each user in search results
  void _updateSearchResults() {
    for (var user in _searchResults) {
      user.isEmergencyContact = _emergencyContactIds.contains(user.id);
    }
  }
  Future<void> searchUser(String query, String currentUserId) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      final lowerCaseQuery = query.toLowerCase();

      // Fetch documents from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get(); // Get all user documents since name is nested

      // Filter documents based on name
      _searchResults = snapshot.docs
          .where((doc) =>
      doc.id != currentUserId && // Exclude the current user
          (doc.data()['name'] as String)
              .toLowerCase()
              .startsWith(lowerCaseQuery)) // Case-insensitive search
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();

      _updateSearchResults(); // Update emergency contact status
      notifyListeners(); // Notify listeners about the changes
    } catch (e) {
      print("Error searching users: $e");
      _searchResults = [];
      notifyListeners();
    }
  }


  Future<void> addEmergencyContact(
      BuildContext context, String userId, String userName) async {
    final loggedInUser = _auth.currentUser;

    if (loggedInUser == null) {
      print('No logged-in user found');
      return;
    }

    try {
      // Add the contact to the logged-in user's emergencyContacts sub-collection
      await FirebaseFirestore.instance
          .collection('users') // Reference to users collection
          .doc(loggedInUser.uid) // Use the logged-in user ID
          .collection('emergencyContacts') // Access emergencyContacts sub-collection
          .doc(userId) // Use the userId as the document ID for the contact
          .set({
        'contactId': userId, // Store contact information here
        'addedAt': FieldValue.serverTimestamp(), // Optionally add a timestamp
      });

      // Update the emergency contact list
      _emergencyContactIds.add(userId);
      _updateSearchResults();

      // Notify UI
      notifyListeners();
      _snackbarService.showSnackbar(
          message: "${userName} added as emergency contact");

      // Clear search results and dismiss the bottom sheet
      _searchResults = [];
      notifyListeners(); // Update the UI to reflect the cleared results
      Navigator.pop(context);
    } catch (e) {
      print("Error adding emergency contact: $e");
    }
  }

  // Future<void> addEmergencyContact(
  //     BuildContext context, String userId, String userName) async {
  //   final loggedInUser = _auth.currentUser;
  //
  //   if (loggedInUser == null) {
  //     print('No logged-in user found');
  //     return;
  //   }
  //
  //   // Add the contact to the logged-in user's emergencyContacts sub-collection
  //   await FirebaseFirestore.instance
  //       .collection('users') // Reference to users collection
  //       .doc(loggedInUser.uid) // Use the logged-in user ID
  //       .collection(
  //           'emergencyContacts') // Access emergencyContacts sub-collection
  //       .doc(userId) // Use the userId as the document ID for the contact
  //       .set({
  //     'contactId':
  //         userId, // Store contact information here (you can add more fields)
  //     'addedAt': FieldValue.serverTimestamp(), // Optionally add a timestamp
  //   });
  //   // Update the emergency contact list and UI
  //   _emergencyContactIds.add(userId);
  //   _updateSearchResults();
  //   notifyListeners();
  //   _snackbarService.showSnackbar(
  //       message: "${userName} added as emergency contact");
  //   Navigator.pop(context);
  // }

  Future<void> removeEmergencyContact(BuildContext context,String userId,String userName) async {
    final loggedInUser = _auth.currentUser;

    if (loggedInUser == null) {
      print('No logged-in user found');
      return;
    }

    // Remove the contact from the logged-in user's emergencyContacts sub-collection
    await FirebaseFirestore.instance
        .collection('users') // Reference to users collection
        .doc(loggedInUser.uid) // Use the logged-in user ID
        .collection(
            'emergencyContacts') // Access emergencyContacts sub-collection
        .doc(userId) // Use the userId as the document ID for the contact
        .delete();
    // Update the emergency contact list and UI
    _emergencyContactIds.remove(userId);
    _updateSearchResults();
    notifyListeners();
    _snackbarService.showSnackbar(
        message: "${userName} removed from emergency contact");

    // Clear search results and dismiss the bottom sheet
    _searchResults = [];
    notifyListeners(); // Update the UI to reflect the cleared results
    Navigator.pop(context);
  }

  // Future<void> saveEmergencyContacts() async {
  //   // Save the updated emergency contacts to Firestore
  //   await FirebaseFirestore.instance
  //       .collection('emergencyContacts')
  //       .doc(loggedInUser.id) // Replace with current user ID
  //       .set({'contacts': _emergencyContactIds});
  // }

  bool isEmergencyContact(String userId) {
    return _emergencyContactIds.contains(userId);
  }
  //
  // Future<void> searchUser(String query, String currentUserId) async {
  //   // Fetch matching users from Firestore, excluding the current user
  //   final snapshot = await FirebaseFirestore.instance
  //       .collection('users')
  //       .where('name', isGreaterThanOrEqualTo: query)
  //       .where('name',
  //           isLessThanOrEqualTo:
  //               query + '\uf8ff') // For case-insensitive search
  //       .get();
  //
  //   _searchResults = snapshot.docs
  //       .where((doc) => doc.id != currentUserId) // Exclude the current user
  //       .map((doc) => UserModel.fromJson(doc.data(), doc.id))
  //       .toList();
  //
  //   // Update each user's emergency contact status
  //   _updateSearchResults();
  //   notifyListeners(); // Update the search results
  // }

  @override
  List<ReactiveServiceMixin> get reactiveServices => [];
}

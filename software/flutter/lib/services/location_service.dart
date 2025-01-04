import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  // Retrieve IP address from SharedPreferences
  Future<void> saveIPAddress(String ipAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ipAddress', ipAddress);
    print('IP Address saved: $ipAddress');
  }
  Future<String?> getIPAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIP = prefs.getString('ipAddress');
    print('Fetched IP Address: $savedIP');
    return savedIP;
  }
  // Request Location Permission
  Future<bool> initializeLocationService() async {
    try {
      // Step 1: Check for location permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false; // Permission denied
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false; // Permission permanently denied
      }

      // Step 2: Check if location services are enabled
      bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        await Geolocator.openLocationSettings();

        // Recheck location services after returning from settings
        isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!isServiceEnabled) {
          return false; // Location services still disabled
        }
      }

      return true; // Permissions granted and location services enabled
    } catch (e) {
      throw Exception('Failed to initialize location service: $e');
    }
  }

  Future<Position> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('Failed to fetch current location: $e');
    }
  }

  // Get the current location
  // Future<Position> getCurrentLocation() async {
  //   bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!isServiceEnabled) {
  //     await Geolocator.openLocationSettings();
  //     throw Exception('Location services are disabled.');
  //   }
  //
  //   var permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       throw Exception('Location permissions are denied');
  //     }
  //   }
  //
  //   if (permission == LocationPermission.deniedForever) {
  //     throw Exception('Location permissions are permanently denied.');
  //   }
  //
  //   return await Geolocator.getCurrentPosition(
  //     desiredAccuracy: LocationAccuracy.high,
  //   );
  // }

  // Check if the button is pressed
  Future<Uint8List> fetchSnapshot(String ipAddress) async {
    try {
      final url = Uri.parse('http://$ipAddress/snapshot');
      final response = await http.get(url);
      print('Fetching snapshot from: $url');

      if (response.statusCode == 200) {
        print(
            'Snapshot fetched successfully. Size: ${response.bodyBytes.lengthInBytes} bytes');
        return response.bodyBytes; // Return image as bytes
      } else {
        print('Failed to fetch snapshot. Status code: ${response.statusCode}');
        throw Exception('Failed to fetch snapshot');
      }
    } catch (e) {
      print('Error fetching snapshot: $e');
      throw Exception('Error fetching snapshot');
    }
  }

  // Check the button status from the /switch endpoint
  Future<bool> checkButtonStatus(String ipAddress) async {
    try {
      final url = Uri.parse('http://$ipAddress/switch');
      final response = await http.get(url);
      print('Checking button status from: $url');

      if (response.statusCode == 200) {
        print('Button status response: ${response.body}');
        // Parse the buttonStatus field from the JSON response
        final jsonData = jsonDecode(response.body);
        final buttonStatus = jsonData['buttonStatus'] ?? '';

        // Check if the buttonStatus is 'Pressed'
        return buttonStatus == 'Pressed';
      } else {
        print(
            'Failed to fetch button status. Status code: ${response.statusCode}');
        throw Exception('Failed to fetch button status');
      }
    } catch (e) {
      print('Error checking button status: $e');
      return false;
    }
  }
}

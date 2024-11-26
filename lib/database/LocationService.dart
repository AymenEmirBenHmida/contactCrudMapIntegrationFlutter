import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService with ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _locationUpdateTimer;
  LatLng? _currentLocation;
  String _phoneNumber = '97433416'; // User's phone number

  // Getter for current location
  LatLng? get currentLocation => _currentLocation;

  // Start the periodic location update every 3 minutes
  void startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _updateLocationToDatabase();
    });
  }

  // Stop the periodic location update
  void stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
  }

  // Update the current location from native code or other sources
  Future<void> updateLocation(LatLng newLocation) async {
    _currentLocation = newLocation;
    notifyListeners();
  }

  // Update the location in the database
  Future<void> _updateLocationToDatabase() async {
    if (_currentLocation == null) return;

    String url =
        "http://192.168.43.196/servicephp/modify_position.php"; // Replace with your server URL

    try {
      var bodyData = json.encode({
        'idposition': _phoneNumber, // The phone number of the user
        'longitude': _currentLocation!.longitude.toString(),
        'latitude': _currentLocation!.latitude.toString(),
      });
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: bodyData,
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == 1) {
          print('Location updated successfully in the background');
        } else {
          print('Error updating location: ${data['message']} background');
        }
      } else {
        print('Failed to update location background');
      }
    } catch (e) {
      print('Error: $e background');
    }
  }
}

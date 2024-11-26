import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SendSmsPage extends StatefulWidget {
  SendSmsPage(
      {super.key,
      required this.addUser,
      required this.user,
      required this.phoneNumber,
      this.initialPosition, // Optional parameter for initial position
      required this.updateList});
  final Function(bool) updateList;
  Map<String, dynamic> user;
  final Function(Map<String, String>) addUser;
  final String phoneNumber;
  final LatLng? initialPosition; // Nullable parameter for initial position

  @override
  State<SendSmsPage> createState() => SendSmsPageState();
}

class SendSmsPageState extends State<SendSmsPage> {
  static const platform = MethodChannel('app/native-code');
  static const eventChannel = EventChannel('app/native-code-event');
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  LatLng? _friendLocation;
  LatLng? _myLocation;

  @override
  void initState() {
    super.initState();
    _setupEventChannel();
    _getCurrentLocation();

    // If initial position is provided, set it as the target
    if (widget.initialPosition != null) {
      setState(() {
        _myLocation = widget.initialPosition; // Set the initial position
        _updateMarkers();
      });
    }
  }

// Method to handle updating user data
  Future<void> _updateUser(long, lat) async {
    String url =
        "http://192.168.43.196/servicephp/modify_position.php"; // Replace with your server URL

    try {
      var bodyData = json.encode({
        'id': widget.user['idposition'].toString(),
        'pseudo': widget.user["pseudo"],
        'numero': widget.user["numero"],
        'longitude': long,
        'latitude': lat,
      });
      print(bodyData);
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: bodyData,
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == 1) {
          // widget.updateList(true);
          // Show success message
          Fluttertoast.showToast(
            msg: "User updated successfully",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          // Call the parent function to update the user in the list
          // Map<String, String> updatedUser = {
          //   'id': widget.user['id'].toString(),
          //   'pseudo': pseudoController.text,
          //   'numero': phoneController.text,
          //   'longitude': longitudeController.text,
          //   'latitude': latitudeController.text,
          // };
          // widget.modifyUser(updatedUser);

          Navigator.pop(context); // Close the page after successful update
        } else {
          Fluttertoast.showToast(
            msg: "Error updating user: ${data['message']}",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Failed to update user",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(
        msg: "An error occurred: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  // Setup event channel to listen for updates on the friend's location
  void _setupEventChannel() {
    eventChannel.receiveBroadcastStream().listen((dynamic event) {
      final locationData = jsonDecode(event as String);
      if (locationData['latitude'] != null &&
          locationData['longitude'] != null) {
        _updateUser(locationData['longitude'], locationData['latitude']);
        setState(() {
          _friendLocation = LatLng(
            locationData['latitude'] as double,
            locationData['longitude'] as double,
          );
          _updateMarkers();
        });
      }
    });
  }

  // Get current location of the user
  Future<void> _getCurrentLocation() async {
    try {
      final result = await platform.invokeMethod('getCurrentLocation');
      setState(() {
        _myLocation = LatLng(
          result['latitude'] as double,
          result['longitude'] as double,
        );
        _updateMarkers();
      });
    } on PlatformException catch (e) {
      print("Failed to get location: ${e.message}");
    }
  }

  // Update the markers based on the current and friend's location
  void _updateMarkers() {
    setState(() {
      _markers = {};
      if (_myLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('my_location'),
            position: _myLocation!,
            infoWindow: const InfoWindow(title: 'My Location'),
          ),
        );
      }
      if (_friendLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('friend_location'),
            position: _friendLocation!,
            infoWindow: const InfoWindow(title: 'Friend\'s Location'),
          ),
        );
      }
    });
  }

  // Request friend's location by passing phone number
  Future<void> _requestFriendLocation() async {
    try {
      await platform.invokeMethod('requestLocation', {
        'phoneNumber': widget.phoneNumber,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location request sent')),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Sharing'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _friendLocation ?? _myLocation ?? const LatLng(0, 0),
                zoom: 14.0,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _requestFriendLocation,
              child: const Text('Request Location'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SendSmsPage2 extends StatefulWidget {
  SendSmsPage2(
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
  State<SendSmsPage2> createState() => SendSmsPage2State();
}

class SendSmsPage2State extends State<SendSmsPage2> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();

    // Initialize the selected location with either the initial position or a default value
    _selectedLocation = widget.initialPosition ??
        LatLng(
          double.parse(widget.user['latitude'] ?? '0.0'),
          double.parse(widget.user['longitude'] ?? '0.0'),
        );
  }

  // Update user position on the server
  Future<void> _updateUserPosition() async {
    String url =
        "http://192.168.43.196/servicephp/modify_position.php"; // Replace with your server URL

    try {
      var bodyData = json.encode({
        'idposition': widget.user['idposition'].toString(),
        'pseudo': widget.user["pseudo"],
        'numero': widget.user["numero"],
        'longitude': _selectedLocation?.longitude.toString(),
        'latitude': _selectedLocation?.latitude.toString(),
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: bodyData,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == 1) {
          Fluttertoast.showToast(
            msg: "Position updated successfully",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          widget.updateList(true);
          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(
            msg: "Error updating position: ${data['message']}",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Failed to update position",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Position'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? const LatLng(0, 0),
                zoom: 14.0,
              ),
              markers: {
                if (_selectedLocation != null)
                  Marker(
                    markerId: const MarkerId('selected_location'),
                    position: _selectedLocation!,
                    draggable: true,
                    onDragEnd: (newPosition) {
                      setState(() {
                        _selectedLocation = newPosition;
                      });
                    },
                  ),
              },
              onTap: (position) {
                setState(() {
                  _selectedLocation = position;
                });
              },
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _updateUserPosition,
              child: const Text('Save Position'),
            ),
          ),
        ],
      ),
    );
  }
}

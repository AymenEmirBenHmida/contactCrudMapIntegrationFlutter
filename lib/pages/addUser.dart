import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Import the fluttertoast package
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:geolocator/geolocator.dart'; // For getting the user's location

class AddUserPage extends StatefulWidget {
  const AddUserPage(
      {super.key, required this.addUser, required this.updateList});
  final Function(Map<String, String>) addUser;
  final Function(bool) updateList;

  @override
  State<AddUserPage> createState() => AddUserPageState();
}

class AddUserPageState extends State<AddUserPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController pseudoController = TextEditingController();
  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();

  double? latitude;
  double? longitude;

  void addUser(user) {
    widget.addUser(user);
  }

  Future<void> _getCurrentLocation() async {
    // Request location permissions
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg: "Location permission denied",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    // Get the current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      latitudeController.text = latitude.toString();
      longitudeController.text = longitude.toString();
    });
  }

  Future<void> addUserToDatabase(Map<String, String> user) async {
    try {
      var boyData = jsonEncode({
        'email': user['email'],
        'pseudo': user['pseudo'],
        'numero': user['phone'],
        'latitude': user['latitude'],
        'longitude': user['longitude'],
      });
      print(boyData);
      final response = await http.post(
        Uri.parse(
            'http://192.168.43.196/servicephp/add_position.php'), // Replace with your actual PHP script URL
        headers: {'Content-Type': 'application/json'},
        body: boyData,
      );
      print(response.body);
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "User added successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        widget.updateList(true);
        Navigator.pop(context); // Navigate back after success
      } else {
        throw Exception('Failed to add user');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.green),
          onPressed: () {},
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Container(
          width: 500,
          height: 400,
          decoration: const BoxDecoration(),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(hintText: "Email"),
                  controller: emailController,
                ),
                TextFormField(
                  decoration: const InputDecoration(hintText: "Pseudo"),
                  controller: pseudoController,
                ),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: "Phone"),
                ),
                TextFormField(
                  controller: latitudeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: "Latitude"),
                ),
                TextFormField(
                  controller: longitudeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: "Longitude"),
                ),
                ElevatedButton(
                  onPressed: _getCurrentLocation,
                  child: const Text("Use Current Location"),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Add new user when the floating button is pressed
                        if (emailController.text == "" ||
                            pseudoController.text == "" ||
                            phoneController.text == "" ||
                            latitudeController.text == "" ||
                            longitudeController.text == "") {
                          Fluttertoast.showToast(
                            msg: "There is an empty field",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        } else {
                          Map<String, String> newUser = {
                            'email': emailController.text,
                            'pseudo': pseudoController.text,
                            'phone': phoneController.text,
                            'latitude': latitudeController.text,
                            'longitude': longitudeController.text,
                          };

                          // Send user data along with position to the database
                          addUserToDatabase(newUser);
                        }
                      },
                      child: const Text(
                        "Add",
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

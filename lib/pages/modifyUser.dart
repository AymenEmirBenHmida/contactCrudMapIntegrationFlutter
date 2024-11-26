import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ModifyUserPage extends StatefulWidget {
  ModifyUserPage(
      {super.key,
      required this.modifyUser,
      required this.user,
      required this.updateList});
  final Function(bool) updateList;
  final Function(Map<String, String>) modifyUser;
  Map<String, dynamic> user;

  @override
  State<ModifyUserPage> createState() => ModifyUserPageState();
}

class ModifyUserPageState extends State<ModifyUserPage> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController pseudoController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
  TextEditingController latitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print(widget.user);
    phoneController.text = widget.user["numero"];
    pseudoController.text = widget.user["pseudo"];
    longitudeController.text = widget.user["longitude"].toString();
    latitudeController.text = widget.user["latitude"].toString();
  }

  // Method to handle updating user data
  Future<void> _updateUser() async {
    String url =
        "http://192.168.43.196/servicephp/modify_position.php"; // Replace with your server URL

    try {
      var bodyData = json.encode({
        'idposition': widget.user['idposition'].toString(),
        'pseudo': pseudoController.text,
        'numero': phoneController.text,
        'longitude': longitudeController.text,
        'latitude': latitudeController.text,
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
          widget.updateList(true);
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
          Map<String, String> updatedUser = {
            'id': widget.user['id'].toString(),
            'pseudo': pseudoController.text,
            'numero': phoneController.text,
            'longitude': longitudeController.text,
            'latitude': latitudeController.text,
          };
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify User'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
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
                controller: longitudeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: "Longitude"),
              ),
              TextFormField(
                controller: latitudeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: "Latitude"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (pseudoController.text.isEmpty ||
                      phoneController.text.isEmpty ||
                      longitudeController.text.isEmpty ||
                      latitudeController.text.isEmpty) {
                    Fluttertoast.showToast(
                      msg: "There is an empty field",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                  } else {
                    _updateUser(); // Call the method to update the user
                  }
                },
                child: const Text("Modify"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

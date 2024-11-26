import 'package:flutter/material.dart';
import 'package:mobile_friends_finding_crud/database/Position.dart';
import 'package:mobile_friends_finding_crud/database/db_helper.dart';
import 'package:mobile_friends_finding_crud/pages/addUser.dart';
import 'package:mobile_friends_finding_crud/pages/modifyUser.dart';
import 'package:mobile_friends_finding_crud/pages/sendSms2.dart';
import 'package:mobile_friends_finding_crud/pages/sendSmsPage.dart'; // Import SendSmsPage
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ListUsersPage extends StatefulWidget {
  const ListUsersPage({super.key, required this.title});
  final String title;

  @override
  State<ListUsersPage> createState() => ListUsersPageState();
}

class ListUsersPageState extends State<ListUsersPage> {
  List<Map<String, dynamic>> listOfUsers = [];
  List<Position> listOfPositions = [];

  @override
  void initState() {
    super.initState();
    // _fetchUsers(); // Fetch users from the database when the page is initialized
    _fetchPositions();
  }

  Future<void> _fetchPositions() async {
    try {
      List<Position> positions = await fetchPositions();
      setState(() {
        listOfPositions = positions;
      });
    } catch (e) {
      // Handle errors (e.g., network issues)
      print('Error fetching positions: $e');
    }
  }

  Future<void> _fetchUsers() async {
    List<Map<String, dynamic>> users = await UserDatabaseHelper().getUsers();
    setState(() {
      listOfUsers = users;
    });
  }

  void _callPhone(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    await launchUrl(launchUri);
  }

  void addUser(Map<String, String> newUser) async {
    // await UserDatabaseHelper().insertUser(newUser);
    // _fetchUsers(); // Refresh the list after adding a user
    await _fetchPositions();
  }

  void modifyUser(Map<String, String> updatedUser) async {
    await UserDatabaseHelper().updateUser(updatedUser);
    _fetchUsers(); // Refresh the list after modifying a user
  }

  // void deleteUser(int id) async {
  //   await UserDatabaseHelper().deleteUser(id);
  //   _fetchUsers(); // Refresh the list after deleting a user
  // }
  void deleteUser(Position position) async {
    bool isDeleted = await position.deletePosition(
        position.idPosition); // Call the delete method of Position class
    if (isDeleted) {
      _fetchPositions(); // Refresh the list after deleting a user
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Position deleted successfully')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete position')));
    }
  }

  // void search(String query) {
  //   if (query.isEmpty) {
  //     _fetchUsers(); // Reset the list when the search query is empty
  //   } else {
  //     setState(() {
  //       listOfUsers = listOfUsers.where((user) {
  //         return user["email"]!.toLowerCase().contains(query.toLowerCase()) ||
  //             user["phone"]!.toLowerCase().contains(query.toLowerCase());
  //       }).toList();
  //     });
  //   }
  // }
  void search(String query) {
    if (query.isEmpty) {
      _fetchPositions(); // Reset the list when the search query is empty
    } else {
      setState(() {
        listOfPositions = listOfPositions.where((position) {
          return position.pseudo.toLowerCase().contains(query.toLowerCase()) ||
              position.numero.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<List<Position>> fetchPositions() async {
    final response = await http
        .get(Uri.parse('http://192.168.43.196/servicephp/get_all.php'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['positions'];
      print(data);
      return data.map((json) => Position.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load positions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddUserPage(
                    addUser: addUser,
                    updateList: (verif) => {if (verif) _fetchPositions()},
                  )),
        ),
        child: const Icon(Icons.add, color: Colors.green),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              onChanged: (value) => search(value),
              decoration: const InputDecoration(hintText: 'Search positions'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: listOfPositions.length,
                itemBuilder: (context, index) {
                  final position = listOfPositions[index];
                  return ListTile(
                    title: Text(position.pseudo),
                    subtitle: Text('Number: ${position.numero}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _callPhone(position.numero),
                          icon: const Icon(Icons.phone, color: Colors.green),
                        ),
                        IconButton(
                          onPressed: () {
                            // Navigate to ModifyUserPage (if needed)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ModifyUserPage(
                                  updateList: (verify) =>
                                      {if (verify) _fetchPositions()},
                                  modifyUser: modifyUser,
                                  user: {
                                    "idposition":
                                        position.idPosition.toString(),
                                    "pseudo": position.pseudo,
                                    "numero": position.numero,
                                    "longitude": position.longitude.toString(),
                                    "latitude": position.latitude.toString(),
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, color: Colors.blue),
                        ),
                        IconButton(
                          onPressed: () {
                            // Handle delete operation (if needed)
                            deleteUser(position);
                            print("hello");
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                        IconButton(
                          onPressed: () {
                            LatLng positi = LatLng(position.latitude,
                                position.longitude); // Example position

                            // Navigate to SendSmsPage and pass the user's phone number
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SendSmsPage(
                                  updateList: (verif) => {
                                    if (verif) {_fetchPositions()}
                                  },
                                  user: {
                                    "idposition":
                                        position.idPosition.toString(),
                                    "pseudo": position.pseudo,
                                    "numero": position.numero,
                                    "longitude": position.longitude.toString(),
                                    "latitude": position.latitude.toString(),
                                  },
                                  addUser: addUser,
                                  phoneNumber: position.numero,
                                  initialPosition: positi,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sms, color: Colors.blue),
                        ),
                        IconButton(
                          onPressed: () {
                            LatLng positi = LatLng(position.latitude,
                                position.longitude); // Example position

                            // Navigate to SendSmsPage and pass the user's phone number
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SendSmsPage2(
                                  updateList: (verif) => {
                                    if (verif) {_fetchPositions()}
                                  },
                                  user: {
                                    "idposition":
                                        position.idPosition.toString(),
                                    "pseudo": position.pseudo,
                                    "numero": position.numero,
                                    "longitude": position.longitude.toString(),
                                    "latitude": position.latitude.toString(),
                                  },
                                  addUser: addUser,
                                  phoneNumber: position.numero,
                                  initialPosition: positi,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map, color: Colors.blue),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

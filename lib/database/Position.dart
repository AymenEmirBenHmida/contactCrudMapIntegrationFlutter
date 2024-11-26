import 'dart:convert';
import 'package:http/http.dart' as http;

class Position {
  final int idPosition;
  final String pseudo;
  final String numero;
  final double longitude;
  final double latitude;

  Position({
    required this.idPosition,
    required this.pseudo,
    required this.numero,
    required this.longitude,
    required this.latitude,
  });

  // Factory method to create Position from JSON
  factory Position.fromJson(Map<String, dynamic> json) {
    print(json['idposition']);
    return Position(
      idPosition: int.parse(json['idposition']),
      pseudo: json['pseudo'],
      numero: json['numero'],
      longitude: double.parse(json['longitude']),
      latitude: double.parse(json['latitude']),
    );
  }
  Future<bool> deletePosition(idPosition) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.43.196/servicephp/delete_position.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idposition': this.idPosition
        }), // Ensure 'idposition' is passed as the key
      );

      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');
        final result = jsonDecode(response.body);
        // Check if the message matches expected success response
        return result['message'] == 'Position deleted successfully.';
      } else {
        throw Exception('Failed to delete position: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to delete position');
    }
  }
}

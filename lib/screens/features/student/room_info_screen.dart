import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/session_manager.dart';

class RoomInfoScreen extends StatefulWidget {
  @override
  _RoomInfoScreenState createState() => _RoomInfoScreenState();
}

class _RoomInfoScreenState extends State<RoomInfoScreen> {
  Map<String, dynamic>? roomData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoomDetails();
  }

  Future<void> _fetchRoomDetails() async {
    String? userId = await SessionManager.getUserId();
    // Use your AppConstants.baseUrl here
    final response = await http.post(
      Uri.parse("http://192.168.1.65/get_room_info.php"),
      body: {"user_id": userId},
    );

    if (response.statusCode == 200) {
      setState(() {
        roomData = json.decode(response.body);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color maroon = Color(0xFF800000); //
    const Color gold = Color(0xFFFFD700);   //

    return Scaffold(
      appBar: AppBar(
        title: Text("ROOM INFORMATION", style: TextStyle(color: gold)),
        backgroundColor: maroon,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: maroon))
          : Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoTile("Room Number", roomData?['room_number'] ?? "N/A", Icons.meeting_room),
            _buildInfoTile("Block", roomData?['block_name'] ?? "N/A", Icons.apartment),
            _buildInfoTile("Type", roomData?['room_type'] ?? "N/A", Icons.bed),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF800000)),
        title: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
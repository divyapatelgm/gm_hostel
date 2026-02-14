import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants.dart';
import '../../../core/session_manager.dart';

class RoomRequestStatusScreen extends StatefulWidget {
  const RoomRequestStatusScreen({super.key});

  @override
  _RoomRequestStatusScreenState createState() => _RoomRequestStatusScreenState();
}

class _RoomRequestStatusScreenState extends State<RoomRequestStatusScreen> {
  final Color maroon = const Color(0xFF4D1C1C);
  final Color gold = const Color(0xFFE5BB6B);

  Future<List<dynamic>> _fetchStatus() async {
    final userId = await SessionManager.getUserId();
    final url = "${AppConstants.baseUrl}/get_student_room_requests.php?student_id=$userId";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load status");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF6ED),
      appBar: AppBar(
        title: const Text("Request Status", style: TextStyle(color: Colors.white)),
        backgroundColor: maroon,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No request history found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final req = snapshot.data![index];
              return _buildStatusCard(req);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(dynamic req) {
    Color statusColor = Colors.orange;
    if (req['status'] == 'approved') statusColor = Colors.green;
    if (req['status'] == 'rejected') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(req['target_room_type'], style: TextStyle(color: maroon, fontWeight: FontWeight.bold)),
              Text(
                req['status'].toString().toUpperCase(),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 20),
          Text("Requested on: ${req['created_at'] ?? 'N/A'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          Text("Reason: ${req['reason']}", style: const TextStyle(fontSize: 13)),

          // MANAGER RESPONSE BOX
          if (req['manager_remarks'] != null && req['manager_remarks'].toString().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: gold.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: maroon),
                      const SizedBox(width: 8),
                      const Text("ALLOCATION NOTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    req['manager_remarks'],
                    style: TextStyle(color: maroon, fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
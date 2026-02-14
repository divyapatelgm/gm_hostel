import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants.dart';
import '../../../core/app_theme.dart';

class ManagerRoomApprovalScreen extends StatefulWidget {
  const ManagerRoomApprovalScreen({super.key});

  @override
  State<ManagerRoomApprovalScreen> createState() => _ManagerRoomApprovalScreenState();
}

class _ManagerRoomApprovalScreenState extends State<ManagerRoomApprovalScreen> {
  List requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchForManager();
  }

  Future<void> _fetchForManager() async {
    setState(() => isLoading = true);
    try {
      final url = "${AppConstants.baseUrl}/get_pending_room_requests.php?role=manager";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          requests = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _allocateRoom(dynamic id) async {
    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}/update_room_request.php"),
      body: {
        "request_id": id.toString(),
        "status": "approved",
      },
    );
    if (response.statusCode == 200) _fetchForManager();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('GM Group of Hostel'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : requests.isEmpty
          ? Center(child: Text("No verified requests pending", style: TextStyle(color: AppTheme.muted)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          return _buildRequestCard(req);
        },
      ),
    );
  }

  Widget _buildRequestCard(dynamic req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Icon(Icons.person, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          req['username'].toString().toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.onBackground),
        ),
        subtitle: Text("Target: ${req['target_block']}", style: TextStyle(fontSize: 12, color: AppTheme.muted)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),

                // Details Section
                _buildDetailRow("Current Room", "${req['current_room_no'] ?? 'N/A'} (${req['current_block'] ?? 'N/A'})"),
                _buildDetailRow("Requested Type", req['target_room_type'] ?? 'N/A'),

                const SizedBox(height: 12),

                // Description Box
                Text("REASON FOR CHANGE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary.withOpacity(0.7))),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Text(
                    req['description'] ?? "No reason provided.",
                    style: TextStyle(fontSize: 13, color: AppTheme.onBackground, fontStyle: FontStyle.italic),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: AppTheme.onBackground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _allocateRoom(req['id']),
                    child: const Text("FINALIZE ALLOCATION", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.muted, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.onBackground, fontSize: 13)),
        ],
      ),
    );
  }
}
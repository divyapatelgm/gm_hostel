import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/session_manager.dart';

class SupervisorPassScreen extends StatefulWidget {
  const SupervisorPassScreen({super.key});

  @override
  State<SupervisorPassScreen> createState() => _SupervisorPassScreenState();
}

class _SupervisorPassScreenState extends State<SupervisorPassScreen> with SingleTickerProviderStateMixin {
  List allRequests = [];
  bool isLoading = true;
  late TabController _tabController;
  final Color maroon = const Color(0xFF5D1F1A);

  Future<void> _showRejectDialog(dynamic passId) async {
    final TextEditingController _remarkController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Pass Request", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _remarkController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Enter reason for rejection...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (_remarkController.text.trim().isEmpty) {
                _showSnackBar("Please provide a reason");
                return;
              }
              Navigator.pop(context); // Close dialog
              _updateStatusWithRemark(passId, 'Rejected', _remarkController.text.trim());
            },
            child: const Text("REJECT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  Future<void> _updateStatusWithRemark(dynamic passId, String status, String remark) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator())
    );

    try {
      String? targetDb = await SessionManager.getSelectedDb();
      String? userID = await SessionManager.getUserId(); // Fetch getUserId()

      final response = await http.post(
        Uri.parse(AppConstants.updatePassUrl),
        body: {
          "pass_id": passId.toString(),
          "status": status,
          "remarks": remark,
          "approved_by":  userID ?? 'Unknown_ID',
          "target_db": targetDb ?? 'gmit_new',
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove progress indicator

      if (response.statusCode == 200) {
        _fetchRequests();
        _showSnackBar("Pass marked as $status");
      } else {
        _showSnackBar("Failed to update status");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Update Error: $e");
      _showSnackBar("An error occurred");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get location values
      String hostel = prefs.getString("hostel") ?? '';
      String block  = prefs.getString("block") ?? '';
      String floor  = prefs.getString("floor") ?? '';

      if (hostel.isEmpty || hostel == "Not Assigned") {
        setState(() => isLoading = false);
        return;
      }

      // Build the URL without the target_db filter to see everyone in this location
      final String url = "${AppConstants.getStudentPassesUrl}"
          "?hostel=${Uri.encodeComponent(hostel)}"
          "&block=${Uri.encodeComponent(block)}"
          "&floor=${Uri.encodeComponent(floor)}";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            allRequests = json.decode(response.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }
  Future<void> _updateStatus(dynamic passId, String status) async {
    // Show a small progress indicator
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      String? targetDb = await SessionManager.getSelectedDb();
      String? userID = await SessionManager.getUserId();

      final response = await http.post(
        Uri.parse(AppConstants.updatePassUrl),
        body: {
          "pass_id": passId.toString(),
          "status": status,
          "approved_by": userID ?? 'Unknown_ID',
          "target_db": targetDb ?? 'gmit_new',
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove progress dialog

      if (response.statusCode == 200) {
        _fetchRequests(); // Automatically moves the item to the "Resolved" tab
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pass marked as $status")));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate lists for the tabs
    final activeRequests = allRequests.where((r) => r['STATUS'] == 'Pending').toList();
    final resolvedRequests = allRequests.where((r) => r['STATUS'] != 'Pending').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      body: Column(
        children: [
          _buildHeader(activeRequests.length),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: maroon))
                : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(activeRequests, isHistory: false),
                _buildRequestList(resolvedRequests, isHistory: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int activeCount) {
    return Container(      padding: const EdgeInsets.fromLTRB(10, 50, 10, 10),
      decoration: BoxDecoration(
        color: maroon,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                "GATE PASS SUPERVISOR",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchRequests,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: const Color(0xFFD4AF37), // Gold accent
            indicatorWeight: 4,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            tabs: [
              Tab(
                text: "PENDING ($activeCount)",
              ),
              const Tab(
                text: "APPROVED",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List list, {required bool isHistory}) {
    if (list.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isHistory ? Icons.history : Icons.done_all, size: 50, color: Colors.grey[300]),
          Text(isHistory ? "No pass history found." : "No pending requests!", style: TextStyle(color: Colors.grey[500])),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildRequestCard(list[index], isHistory),
    );
  }

  Widget _buildRequestCard(Map item, bool isHistory) {
    // UPDATED: Match Uppercase keys
    bool hasDocument = item['DOCUMENT_PATH'] != null && item['DOCUMENT_PATH'] != "";

    return Card(
      // ... card styling
      child: ExpansionTile(
        title: Text(item['NAME'] ?? "Unknown Student", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item['PASS_TYPE'] ?? "Pass"),
        leading: Icon(
          isHistory ? Icons.check_circle : Icons.pending,
          color: isHistory ? Colors.green : maroon,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                // Use Uppercase keys for all these rows
                _infoRow(Icons.location_on, "Location", "${item['HOSTEL']} | B: ${item['BLOCK']} | F: ${item['FLOOR']}"),
                _infoRow(Icons.notes, "Reason", item['REASON'] ?? "N/A"),
                _infoRow(Icons.school, "College", item['DB_COLUMN'] ?? "N/A"),
                _infoRow(Icons.info_outline, "Status", item['STATUS'], color: _getStatusColor(item['STATUS'])),

                if (item['REMARKS'] != null && item['REMARKS'] != "")
                  _infoRow(Icons.comment, "Warden Remark", item['REMARKS'], color: Colors.redAccent),

                const SizedBox(height: 15),

                // UPDATED: 'PHONE' or 'PARENT_MOBILE' depending on your schema
                if (item['PHONE'] != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri(scheme: 'tel', path: item['PHONE'].toString())),
                      icon: const Icon(Icons.phone, size: 18),
                      label: Text("Call Student (${item['PHONE']})"),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                    ),
                  ),

                if (hasDocument)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAttachmentDialog(item['DOCUMENT_PATH']),
                        icon: const Icon(Icons.image, color: Colors.white, size: 18),
                        label: const Text("View Support Document", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                      ),
                    ),
                  ),

                if (!isHistory) ...[
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          // UPDATED: 'ID'
                          onPressed: () => _updateStatus(item['ID'], 'Approved'),
                          child: const Text("APPROVE", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          // UPDATED: 'ID'
                          onPressed: () => _showRejectDialog(item['ID']),
                          child: const Text("REJECT", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: maroon),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: color))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.green;
      case 'Rejected': return Colors.red;
      case 'Left Campus': return Colors.orange;
      case 'Returned': return Colors.blue;
      default: return Colors.grey;
    }
  }


  void _showAttachmentDialog(String fileName) {
    final String imageUrl = "${AppConstants.baseUrl}/uploads/documents/$fileName";
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(imageUrl, fit: BoxFit.contain),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
          ],
        ),
      ),
    );
  }
}

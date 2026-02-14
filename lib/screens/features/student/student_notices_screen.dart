import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants.dart';
import '../../../core/session_manager.dart';

class StudentNoticeScreen extends StatefulWidget {
  const StudentNoticeScreen({super.key});

  @override
  State<StudentNoticeScreen> createState() => _StudentNoticeScreenState();
}

class _StudentNoticeScreenState extends State<StudentNoticeScreen> {
  // Pull-to-refresh logic
  Future<List> _fetchNotices() async {
    String? db = await SessionManager.getSelectedDb();
    String? hostel = await SessionManager.getHostel();

    // Corrected URL construction with proper encoding
    final String url = "${AppConstants.getnoticesUrl}"
        "?target_db=${db ?? ''}"
        "&hostel=${Uri.encodeComponent(hostel?.replaceAll('-', ' ') ?? '')}";
    debugPrint("DEBUGGING NOTICE URL: $url");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("Notice Fetch Error: $e");
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0), // Soft background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("HOSTEL NOTICES",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 15)),
        backgroundColor: const Color(0xFF5D1F1A),
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<List>(
          future: _fetchNotices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF800000)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var notice = snapshot.data![index];
                return _buildNoticeCard(notice);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoticeCard(Map notice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign, color: Color(0xFFD4AF37)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(notice['TITLE'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF800000))),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(notice['CONTENT'], style: TextStyle(color: Colors.grey[800], height: 1.4)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("By: ${notice['POSTED_BY']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                Text(notice['CREATED_AT'].toString().substring(0, 16),
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("No notices for your hostel yet.", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
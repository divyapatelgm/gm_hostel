import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants.dart';
import '../../../core/session_manager.dart';

class SupervisorNoticeScreen extends StatefulWidget {
  const SupervisorNoticeScreen({super.key});

  @override
  State<SupervisorNoticeScreen> createState() => _SupervisorNoticeScreenState();
}

class _SupervisorNoticeScreenState extends State<SupervisorNoticeScreen> {
  List myNotices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyNotices();
  }

  Future<void> _fetchMyNotices() async {
    setState(() => isLoading = true);
    String? db = await SessionManager.getSelectedDb();
    String? hostel = await SessionManager.getHostel();

    // Using the same fetch script we created for students
    final response = await http.get(Uri.parse(
        "${AppConstants.baseUrl}/get_notices.php?target_db=$db&hostel=$hostel"
    ));

    if (response.statusCode == 200) {
      setState(() {
        myNotices = json.decode(response.body);
        isLoading = false;
      });
    }
  }

  // UI for the "Create Notice" Popup
  void _showCreateNoticeDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Broadcast New Notice",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
            const SizedBox(height: 15),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Notice Title", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Description / Content", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800000)),
                onPressed: () {
                  if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                    _submitNotice(titleController.text, contentController.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text("POST ANNOUNCEMENT", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitNotice(String title, String content) async {
    try {
      String? db = await SessionManager.getSelectedDb();
      String? hostel = await SessionManager.getHostel();
      String? name = await SessionManager.getUserName();

      // Log this to your console to see what is being sent
      print("Sending: Title: $title, DB: $db, Hostel: $hostel");

      final response = await http.post(
        Uri.parse(AppConstants.postnoticeUrl),
        body: {
          "title": title,
          "content": content,
          "posted_by": name ?? "Supervisor",
          "target_db": db ?? "gmu", // Ensure this isn't null
          "hostel": hostel ?? "General",
        },
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == 'success') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Notice Published Successfully")),
          );
          _fetchMyNotices(); // Refresh list
        } else {
          print("Server Error: ${res['message']}");
        }
      }
    } catch (e) {
      print("Network Error: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("POST NOTICES",   style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18)),
        backgroundColor: const Color(0xFF5D1F1A),
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),

      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD4AF37),
        onPressed: _showCreateNoticeDialog,
        label: const Text("NEW NOTICE"),
        icon: const Icon(Icons.add),
        
      ),
      
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: myNotices.length,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            title: Text(myNotices[index]['TITLE'] ?? "No Title", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(myNotices[index]['CONTENT'] ?? ""),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }
}

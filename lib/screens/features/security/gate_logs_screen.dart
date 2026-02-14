import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';

class GateLogsScreen extends StatefulWidget {
  const GateLogsScreen({super.key});

  @override
  State<GateLogsScreen> createState() => _GateLogsScreenState();
}

class _GateLogsScreenState extends State<GateLogsScreen> {
  List logs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("${AppConstants.getverifyPassUrl}/get_gate_logs.php"));
      if (response.statusCode == 200) {
        setState(() {
          logs = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ENTRY / EXIT LOGS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF800000),
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _fetchLogs, icon: const Icon(Icons.refresh))],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: logs.length,
        padding: const EdgeInsets.all(10),
        itemBuilder: (context, index) {
          final log = logs[index];
          bool isEntry = log['status'] == 'Returned';
          String time = isEntry ? log['scanned_in_time'] : log['scanned_out_time'];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10)
            ),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(
                isEntry ? Icons.arrow_circle_down : Icons.arrow_circle_up,
                color: isEntry ? Colors.green : Colors.orange,
                size: 32,
              ),
              title: Text(log['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${log['pass_type']} • ${log['db_column']}"),
                  const SizedBox(height: 4),
                  Text("Time: $time", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(5)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("GUARD", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                    Text(log['scanned_by'] ?? "System", style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
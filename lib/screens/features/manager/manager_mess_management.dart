import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants.dart';
import '../../../core/app_theme.dart';

class ManagerMessManagement extends StatefulWidget {
  const ManagerMessManagement({super.key});

  @override
  State<ManagerMessManagement> createState() => _ManagerMessManagementState();
}

class _ManagerMessManagementState extends State<ManagerMessManagement> {
  List<Map<String, dynamic>> polls = [];
  bool isLoading = true;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    _fetchAllPolls();
  }

  Future<void> _fetchAllPolls() async {
    try {
      final response = await http.get(
        Uri.parse("${AppConstants.baseUrl}/get_all_polls.php"),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            polls = List<Map<String, dynamic>>.from(data['polls'] ?? []);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching polls: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _deletePoll(int pollId, int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Poll?"),
        content: const Text("This poll will be deleted and won't appear for students."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isDeleting = true);

              try {
                final response = await http.post(
                  Uri.parse("${AppConstants.baseUrl}/delete_poll.php"),
                  body: {"poll_id": pollId.toString()},
                );

                if (!mounted) return;

                final result = json.decode(response.body);
                if (result['status'] == 'success') {
                  setState(() {
                    polls.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Poll deleted successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? "Failed to delete"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Delete error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() => isDeleting = false);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mess Management'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : polls.isEmpty
              ? Center(
                  child: Text(
                    "No polls created yet",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAllPolls,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: polls.length,
                    itemBuilder: (context, index) {
                      final poll = polls[index];
                      final optionsList =
                          poll['options_list'].toString().split(',').map((e) => e.trim()).toList();
                      final votes = poll['votes'] ?? [];
                      final totalVotes = votes is List
                          ? (votes as List).fold(0, (sum, val) => sum + (val is int ? val : 0))
                          : 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    poll['question'] ?? "Poll",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppTheme.primary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isDeleting)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deletePoll(poll['id'] ?? 0, index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Total Votes: $totalVotes",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...optionsList.asMap().entries.map((entry) {
                              int idx = entry.key;
                              String option = entry.value;
                              int count = votes is List && idx < votes.length
                                  ? (votes[idx] is int ? votes[idx] : 0)
                                  : 0;
                              double percent = totalVotes > 0 ? count / totalVotes : 0.0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          option,
                                          style: TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                        Text(
                                          "$count (${(percent * 100).toStringAsFixed(1)}%)",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percent.clamp(0.0, 1.0),
                                        minHeight: 8,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

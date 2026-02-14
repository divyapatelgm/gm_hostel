import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants.dart';
import '../../../core/app_theme.dart';

class ManagerMessPollScreen extends StatefulWidget {
  const ManagerMessPollScreen({super.key});

  @override
  State<ManagerMessPollScreen> createState() => _ManagerMessPollScreenState();
}

class _ManagerMessPollScreenState extends State<ManagerMessPollScreen> {

  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isPublishing = false;

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  Future<void> _publishPoll() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a question")),
      );
      return;
    }

    setState(() => _isPublishing = true);

    // Combine options into a comma-separated string
    String optionsString = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .join(',');

    try {
      final response = await http.post(
        Uri.parse("${AppConstants.baseUrl}/create_poll.php"),
        body: {
          "question": _questionController.text.trim(),
          "options": optionsString,
        },
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Poll Published Successfully!")),
        );
        Navigator.pop(context);
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('GM Group of Hostel'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Create Mess Poll", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onBackground)),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: "Poll Question",
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _optionControllers.length,
                itemBuilder: (c, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _optionControllers[i],
                    decoration: InputDecoration(
                      labelText: "Option ${i + 1}",
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                    ),
                  ),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addOption,
              icon: Icon(Icons.add_rounded, color: AppTheme.primary),
              label: Text("Add Option", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isPublishing ? null : _publishPoll,
                child: _isPublishing
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("PUBLISH POLL", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants.dart';
import '../../../core/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AdminMenuUpdateScreen extends StatefulWidget {
  const AdminMenuUpdateScreen({super.key});

  @override
  State<AdminMenuUpdateScreen> createState() => _AdminMenuUpdateScreenState();
}

class _AdminMenuUpdateScreenState extends State<AdminMenuUpdateScreen> {
  Uint8List? _imageBytes;
  String? _fileName;
  String _selectedDay = 'Mon'; // Default day changed to short form
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Changed to 3-letter abbreviations to match database table
  final List<String> _days = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      if (pickedFile != null) {
        final Uint8List bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _fileName = pickedFile.name;
        });
      }
    } catch (e) {
      debugPrint("Pick Image Error: $e");
    }
  }

  Future<void> _uploadMenuImage() async {
    if (_imageBytes == null) return;

    setState(() => _isUploading = true);
    try {
      String base64Image = base64Encode(_imageBytes!);

      final response = await http.post(
        Uri.parse(AppConstants.baseUrl),
        body: {
          "image": base64Image,
          "name": _fileName ?? "menu.jpg",
          "day_name": _selectedDay, // Sending 'Mon', 'Tue', etc.
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint("Server Response Code: ${response.statusCode}");
      debugPrint("Server Response Body: ${response.body}");
      
      if (response.body.trim().startsWith('{')) {
        final data = json.decode(response.body);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Update Successful")),
        );
        
        if (data['status'] == 'success') {
          setState(() {
            _imageBytes = null;
            _fileName = null;
          });
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server format error. Check logs.")),
        );
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Menu Photo"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Day", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDay,
                  isExpanded: true,
                  items: _days.map((String day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedDay = newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: _imageBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 60, color: AppTheme.primary.withOpacity(0.5)),
                          const SizedBox(height: 10),
                          const Text("Tap to select Menu Photo", style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                      ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isUploading || _imageBytes == null ? null : _uploadMenuImage,
                icon: _isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_rounded),
                label: Text(_isUploading ? "UPLOADING..." : "POST PHOTO MENU", 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

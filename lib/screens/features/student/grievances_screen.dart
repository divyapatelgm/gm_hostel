import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/session_manager.dart';
import '../../../core/constants.dart';

class StudentGrievanceScreen extends StatefulWidget {
  const StudentGrievanceScreen({super.key});

  @override
  _StudentGrievanceScreenState createState() => _StudentGrievanceScreenState();
}

class _StudentGrievanceScreenState extends State<StudentGrievanceScreen> {
  List grievances = [];
  bool isLoading = true;
  File? _selectedImage;
  String selectedFilter = "All";

  // Brand Colors from your image
  final Color primaryColor = const Color(0xFF5D1F1A); // Maroon
  final Color accentColor = const Color(0xFFD4AF37);  // Gold Button
  final Color bgColor = const Color(0xFFFFF9F3);      // Soft cream background
  final Color statusPending = const Color(0xFFE67E22);
  final Color statusSolved = const Color(0xFF27AE60);

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final String? userId = await SessionManager.getUserId();
    final String? selectedDb = await SessionManager.getSelectedDb();
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse(AppConstants.grievanceUrl),
        body: {
          'action': 'fetch',

          'role': 'STUDENT',
          'user_id': userId,
          'target_db': selectedDb ?? 'gmit_new',
        },
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          grievances = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    // Filter logic for the modern pill buttons
    List filteredList = grievances;
    if (selectedFilter == "Pending") {
      filteredList = grievances.where((g) => g['STATUS']?.toString().toUpperCase() != 'SOLVED').toList();
    } else if (selectedFilter == "Solved") {
      filteredList = grievances.where((g) => g['STATUS']?.toString().toUpperCase() == 'SOLVED').toList();
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 25),
                // MOVED WELCOME TEXT HERE
                Text("Welcome back,",
                    style: GoogleFonts.inter(color: Colors.black54, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Your Grievances",
                    style: GoogleFonts.inter(color: primaryColor, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                _buildNewRequestButton(),
                const SizedBox(height: 25),
                _buildFilterRow(),
                const SizedBox(height: 20),
                ...filteredList.map((item) => _buildImageStyleCard(item)).toList(),
                const SizedBox(height: 100), // Space for FAB if needed
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    "GRIEVANCE HUB",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2),
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balancing back button
            ],
          ),
        ],

      ),
    );
  }

  Widget _buildNewRequestButton() {

    return GestureDetector(
      onTap: _showGrievanceForm,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: Color(0xFF2C1810), size: 24),
            const SizedBox(width: 10),
            Text("NEW GRIEVANCE REQUEST",
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF2C1810), fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ["All", "Pending", "Solved"].map((filter) {
          bool isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
              ),
              selected: isSelected,
              onSelected: (val) => setState(() => selectedFilter = filter),
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade200)),
              showCheckmark: false,
              elevation: 2,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageStyleCard(Map item) {
    bool isSolved = item['STATUS']?.toString().toUpperCase() == 'SOLVED';
    Color statusColor = isSolved ? statusSolved : statusPending;

    // String rawGrievance = item['GRIEVANCE'] ?? "";
    String displayGrievance = item['GRIEVANCE'] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_filled, color: statusColor, size: 18),
                    const SizedBox(width: 8),
                    Text(item['STATUS']?.toString().toUpperCase() ?? "PENDING",
                        style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                  ],
                ),
                // Text("#${item['GRIEVANCE_ID']}", style: const TextStyle(color: Colors.black26, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['SUB_DEPT'] ?? "General",
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810))),
                const SizedBox(height: 12),

                // Date Row
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black38),
                    const SizedBox(width: 8),
                    Text("Filed: ${item['APPLIED_DATE']}", style: GoogleFonts.inter(color: Colors.black54, fontSize: 13)),
                  ],
                ),

                const SizedBox(height: 8),

                // Location Row
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.black38),
                    const SizedBox(width: 8),
                    Text("${item['MAIN_DEPT']}", style: GoogleFonts.inter(color: Colors.black54, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Text("Reason: ${item['GRIEVANCE']}", style: GoogleFonts.inter(color: Colors.black54, fontSize: 13, letterSpacing: 0.5, height: 1.5)),
                  ],
                ),


                if (isSolved) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(),
                  ),
                  Text("Resolution provided.", style: GoogleFonts.inter(color: statusSolved, fontStyle: FontStyle.italic, fontSize: 12)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FORM LOGIC (Modified to match image aesthetic) ---

  void _showGrievanceForm() async {
    final String name = await SessionManager.getUserName() ?? "Student";
    final String id = await SessionManager.getUserId() ?? "N/A";
    final String? selectedDb = await SessionManager.getSelectedDb();
    final String rawHostel = await SessionManager.getHostel() ?? "Not Assigned";
    final String b = await SessionManager.getBlock() ?? "N/A";
    final String f = await SessionManager.getFloor() ?? "N/A";

    String displayHostel = rawHostel;
    if (rawHostel == "N/A" || rawHostel == "Not Assigned" || rawHostel.isEmpty) {
      displayHostel = (selectedDb == 'gmit_new') ? "GMIT Institute" : "GMU Institute";
    }

    String selRegarding = "Electrical";
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // For custom shape
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 30, left: 24, right: 24, top: 15),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 25),
                Text("New Grievance", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 24, color: primaryColor)),
                const SizedBox(height: 20),

                // Meta Info Box
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      _metaRow("Hostel/Campus", displayHostel),
                      const Divider(),
                      _metaRow("Student", name),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _label("ISSUE CATEGORY"),
                DropdownButtonFormField<String>(
                  value: selRegarding,
                  decoration: _fieldStyle(),
                  items: ["Security", "Housekeeping", "Electrical", "Water Supply", "Plumbing","Mess", "Other"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setModalState(() => selRegarding = v!),
                ),
                const SizedBox(height: 20),
                _label("DESCRIPTION"),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: _fieldStyle(hint: "Tell us more about the issue..."),
                ),

                const SizedBox(height: 20),
                _label("ATTACH PHOTO (OPTIONAL)"),
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setModalState(() => _selectedImage = File(image.path));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[50],
                    ),
                    child: _selectedImage == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.camera_alt_outlined, color: Colors.grey),
                        Text("Upload evidence", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () => _submitGrievance(displayHostel, selRegarding, descController.text),
                    child: const Text("SUBMIT GRIEVANCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitGrievance(String hostel, String category, String description) async {
    if (description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a description")),
      );
      return;
    }

    final String? userId = await SessionManager.getUserId();
    final String? selectedDb = await SessionManager.getSelectedDb();
    final String? mobile = await SessionManager.getMobile();


    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      var request = http.MultipartRequest('POST', Uri.parse(AppConstants.grievanceUrl));

      request.fields.addAll({
        'action': 'submit',
        'user_id': userId ?? "",
        'target_db': selectedDb ?? 'gmit_new',
        'name': await SessionManager.getUserName() ?? "Student",
        'hostel': hostel,
        'category': category,
        'description': description,
        'block': await SessionManager.getBlock() ?? "N/A",
        'floor': await SessionManager.getFloor() ?? "N/A",
        'mobile': mobile ?? "",
        'GRIEVANCE': description,
      });

      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'attachment',
          _selectedImage!.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (mounted) Navigator.pop(context); // Remove loading

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          if (mounted) Navigator.pop(context); // Close bottom sheet
          _fetchHistory(); // Refresh list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Grievance submitted successfully!")),
          );
        } else {
          throw Exception(result['message'] ?? "Submission failed");
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Remove loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  // --- SMALL HELPERS ---

  Widget _metaRow(String l, String v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: const TextStyle(color: Colors.black45, fontSize: 13)),
      Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    ],
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(t, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: primaryColor, letterSpacing: 1)),
  );

  InputDecoration _fieldStyle({String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.all(18),
  );
}
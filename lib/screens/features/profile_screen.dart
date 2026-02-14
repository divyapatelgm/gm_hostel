import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/session_manager.dart';
import '../../core/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  String? role;
  bool isLoading = true;

  // Project Branding Colors
  final Color primaryColor = const Color(0xFF5D1F1A); // GM Maroon
  final Color accentColor = const Color(0xFFE2B458);  // GM Gold
  final Color bgColor = const Color(0xFFF8F6F3);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final String? sId = await SessionManager.getUserId();
      final String? sName = await SessionManager.getUserName();
      final String? sRole = await SessionManager.getUserGroup();
      final String? sDb = await SessionManager.getSelectedDb();

      // 1. Initial State from Session
      if (sId != null && mounted) {
        setState(() {
          // Normalize role logic exactly like LoginScreen
          role = _normalizeRole(sRole ?? 'student');
          userData = {
            "ID": sId,
            "NAME": sName,
            "USER_GROUP": sRole,
          };
          if (sName != null) isLoading = false;
        });
      }

      if (sId == null || sId == "N/A") return;

      // 2. API Data Fetching
      final response = await http.post(
        Uri.parse(AppConstants.profileUrl),
        body: {
          "user_id": sId,
          "role": sRole?.toLowerCase() ?? 'student',
          "target_db": sDb ?? 'gmit_new'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          final Map<String, dynamic> fetchedData = result['data'];

          // Protect session from "N/A" corruption
          var newId = fetchedData['ID'] ?? fetchedData['id'];
          if (newId != null && newId.toString().isNotEmpty && newId.toString() != "N/A") {
            await SessionManager.saveUserSession(fetchedData, sDb ?? 'gmit_new');
          }

          if (mounted) {
            setState(() {
              userData = fetchedData;
              // Update role strictly from DESIGNATION column as requested
              role = _normalizeRole(fetchedData['DESIGNATION'] ?? sRole);
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _normalizeRole(dynamic raw) {
    String r = raw.toString().toLowerCase();
    if (r.contains('supervisor')) return 'supervisor';
    if (r.contains('manager') || r.contains('office')) return 'manager';
    if (r.contains('security')) return 'security';
    return 'student';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("MY PROFILE",
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: (role == 'student')
                  ? _buildStudentSection()
                  : _buildStaffSection(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 35, top: 10),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 60, color: primaryColor),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            userData?['NAME']?.toString().toUpperCase() ?? 'N/A',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(20)),
            child: Text(
              role?.toUpperCase() ?? 'USER',
              style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSection() {
    return Column(
      children: [
        _buildDataCard("ACADEMIC DETAILS", Icons.school, {
          "College": userData?['COLLEGE'],
          "USN": userData?['USN'] ?? userData?['ID'],
          "Course": userData?['PROGRAMME'],
          "Year": userData?['YEAR'],
        }),
        _buildDataCard("HOSTEL ALLOCATION", Icons.hotel, {
          "Hostel Name": userData?['HOSTEL'],
          "Block / Floor": "${userData?['BLOCK']} / ${userData?['FLOOR']}",
          "Room Number": userData?['ROOM_NO'],
          "Room Type": userData?['ROOM_TYPE'],
        }),
      ],
    );
  }

  Widget _buildStaffSection() {
    return _buildDataCard("EMPLOYMENT DETAILS", Icons.badge, {
      "Employee ID": userData?['ID'],
      "Designation": userData?['DESIGNATION'],
      "Department": userData?['USER_GROUP'],
      "Contact": userData?['MOBILE_NO'],
    });
  }

  Widget _buildDataCard(String title, IconData icon, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: primaryColor, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...data.entries.map((e) => _buildDataRow(e.key, e.value)).toList(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text(value?.toString() ?? 'N/A', style: GoogleFonts.inter(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

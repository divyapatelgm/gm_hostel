write_file(
    absolutePath="C:/Documents/Flutter Projects/hostel/lib/screens/features/supervisor/supervisor_grievance_screen.dart",
    text="""import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/session_manager.dart';
import '../../../core/constants.dart';

class SupervisorGrievanceScreen extends StatefulWidget {
  const SupervisorGrievanceScreen({super.key});

  @override
  State<SupervisorGrievanceScreen> createState() => _SupervisorGrievanceScreenState();
}

class _SupervisorGrievanceScreenState extends State<SupervisorGrievanceScreen> with SingleTickerProviderStateMixin {
  List allGrievances = [];
  bool isLoading = true;
  late TabController _tabController;
  String lastSync = "Never";
  // Filter States
  String selectedBlock = 'All';
  String selectedHostel = 'All';

  // Branding Colors
  final Color primaryColor = const Color(0xFF5D1F1A);
  final Color accentColor = const Color(0xFFD4AF37);
  final Color bgColor = const Color(0xFFFFF9F3);

  final List<String> blocks = ['All', 'A', 'B', 'C', 'D', 'N/A'];
  // final List<String> floors = ['All', 'Ground Floor', '1st Floor', '2nd Floor', '3rd Floor', 'N/A'];
  final List<String> hostels = ['All', 'GMIT Institute', 'GMU Institute', 'BOYS-HOSTEL', 'GIRLS-HOSTEL'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllGrievances();
  }

  Future<void> _fetchAllGrievances() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
      Uri.parse(AppConstants.getAllGrievancesUrl),
      body: {
        'action': 'fetch',
      },
    );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          allGrievances = data;
          lastSync = "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _resolveGrievance(String ticketId) async {
    // 1. Show Loading Dialog
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator())
    );

    try {
      final response = await http.post(
        Uri.parse(AppConstants.solveGrievanceUrl),
        body: {
          'ticket_id': ticketId,
          'status': 'SOLVED',
        },
      ).timeout(const Duration(seconds: 10)); // Added timeout for safety

      // 2. Close Loading Dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == 'success') {
          // 3. CRITICAL: Re-fetch everything from DB to ensure sync
          await _fetchAllGrievances();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Database Updated: Grievance Resolved"),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          debugPrint("Server Error: ${res['message']}");
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Network Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate Lists based on Status
    final activeList = _applyFilters(allGrievances.where((g) => g['STATUS'] != 'SOLVED').toList());
    final resolvedList = _applyFilters(allGrievances.where((g) => g['STATUS'] == 'SOLVED').toList());

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(activeList.length),
          _buildFilterSection(),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : TabBarView(
              controller: _tabController,
              children: [
                _buildTicketList(activeList, isResolvedTab: false),
                _buildTicketList(resolvedList, isResolvedTab: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int activeCount) {
    return Container(

      padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30)
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
              Text("SUPERVISOR HUB", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchAllGrievances),
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
              Tab(text: "ACTIVE ($activeCount)"),
              const Tab(text: "RESOLVED"),

            ],
          ),
        ],
      ),

    );
  }

  List _applyFilters(List list) {
    return list.where((g) {
      // 1. Get Values (Ensuring they aren't null)
      String hVal = (g['MAIN_DEPT'] ?? '').toString().trim();
      String bVal = (g['BLOCK'] ?? '').toString().trim();
       String fVal = (g['FLOOR'] ?? '').toString().trim();

      // 2. Logic for Hostel
      // If "All" is selected, it passes. Otherwise, it must match exactly.
      bool hMatch = selectedHostel == 'All' || hVal == selectedHostel;

      // 3. Logic for Block
      bool bMatch = selectedBlock == 'All' || bVal == selectedBlock;

      // 4. Logic for Floor


      return hMatch && bMatch;
    }).toList();
  }

  Widget _buildTicketList(List list, {required bool isResolvedTab}) {
    if (list.isEmpty) return _buildEmptyState(isResolvedTab);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildTicketCard(list[index], isResolvedTab),
    );
  }

  Widget _buildTicketCard(Map g, bool isResolvedTab) {
    // DIRECT ACCESS: No more splitting strings!
    String displayDescription = g['GRIEVANCE'] ?? "No Description Provided";
    String blockDisplay = g['BLOCK'] ?? "N/A";
    String floorDisplay = g['FLOOR'] ?? "N/A";
    String sourceTag = g['MAIN_DEPT'] ?? "General";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
            isResolvedTab ? Icons.check_circle : Icons.pending_actions,
            color: isResolvedTab ? Colors.green : primaryColor
        ),
        title: Text(g['SUB_DEPT'] ?? "General",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2C1810))),
        subtitle: Text("$sourceTag • ${g['NAME']}", style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                // Displaying the joined data clearly
                Row(
                  children: [
                    Expanded(child: _infoRow(Icons.meeting_room, "Block", blockDisplay)),
                    Expanded(child: _infoRow(Icons.layers, "Floor", floorDisplay)),
                  ],
                ),
                const SizedBox(height: 12),
                Text("DESCRIPTION:",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                const SizedBox(height: 4),
                Text(displayDescription,
                    style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),

                if (g['ATTACHMENT'] != null && g['ATTACHMENT'].toString().isNotEmpty && g['ATTACHMENT'] != "null")
                  _buildAttachmentButton(g['ATTACHMENT']),

                if (!isResolvedTab) ...[
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _resolveGrievance(g['TICKET_ID'].toString()),
                      icon: const Icon(Icons.done_all, color: Colors.white),
                      label: const Text("MARK AS RESOLVED",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12)
                      ),
                    ),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAttachmentButton(String fileName) {
    final String imageUrl = "${AppConstants.baseUrl.replaceAll(RegExp(r'/[^/]+\.php'), '')}/uploads/$fileName";

    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => _showImagePreview(imageUrl),
        icon: Icon(Icons.image, size: 18, color: primaryColor),
        label: Text("VIEW ATTACHMENT", style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain))),
            Positioned(
                top: 40,
                right: 20,
                child: CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterDropdown("Hostel", selectedHostel, hostels, (v) => setState(() => selectedHostel = v!)),
            const SizedBox(width: 25),
            _filterDropdown("Block", selectedBlock, blocks, (v) => setState(() => selectedBlock = v!)),
            const SizedBox(width: 25),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown(String hint, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 6),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          )
        ]
    ),
  );

  Widget _buildEmptyState(bool isResolvedTab) => Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isResolvedTab ? Icons.check_circle_outline : Icons.done_all, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(isResolvedTab ? "No resolved grievances yet." : "No active grievances found!", style: TextStyle(color: Colors.grey[500]))
          ]
      )
  );
}"""
)

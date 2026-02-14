import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hostel/core/constants.dart';
import 'package:hostel/core/session_manager.dart';
import 'package:image_picker/image_picker.dart';

class SecurityScanner extends StatefulWidget {
  const SecurityScanner({super.key});
  @override
  State<SecurityScanner> createState() => _SecurityScannerState();
}

class _SecurityScannerState extends State<SecurityScanner> with WidgetsBindingObserver {
  bool isScanning = true;
  List history = [];
  bool isHistoryLoading = false;
  final ImagePicker _picker = ImagePicker();
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  // --- TAB 1: SCANNER LOGIC ---

  Future<void> verifyPass(String rawCode) async {
    if (!isScanning) return;

    // Support both raw IDs and the "PASS_ID:" prefix
    String cleanId = rawCode.replaceAll("PASS_ID:", "").trim();
    String? userId = await SessionManager.getUserId();
    String? targetDb = await SessionManager.getSelectedDb();
    setState(() => isScanning = false);
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator())
    );

    try {
      final response = await http.post(
        Uri.parse(AppConstants.verifyPass),
        headers: {"Content-Type": "application/json"},
        // We no longer need to send target_db because the script hits 'gmu' centrally
        body: jsonEncode({
          "pass_id": cleanId,
          "scanned_by": userId ?? 'Unknown_ID', // NEW FIELD
        }),
      );

      debugPrint("Server Response: ${response.body}");
      final result = jsonDecode(response.body);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loader

      // Ensure we have an ID for further actions if needed
      result['id'] = cleanId;
      _showResultDialog(result);

    } catch (e) {
      debugPrint("Scan Error: $e");
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => isScanning = true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Network Error or Invalid Response"))
        );
      }
    }
  }

  Future<void> _updatePassAction(String passId, String newStatus) async {
    String? targetDb = await SessionManager.getSelectedDb();

    // DEBUG 1: Check what is being sent
    print("DEBUG: Sending Update Request");
    print("DEBUG: URL: ${AppConstants.updatePassUrl}");
    print("DEBUG: Body: ${{
      "pass_id": passId,
      "status": newStatus,
      "target_db": targetDb ?? 'gmit_new',
    }}");

    try {
      final response = await http.post(
        Uri.parse(AppConstants.updatePassUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pass_id": passId,
          "status": newStatus,
          "target_db": targetDb ?? 'gmit_new',
        }),
      );

      // DEBUG 2: Check the server response
      print("DEBUG: Server Response Code: ${response.statusCode}");
      print("DEBUG: Server Response Body: ${response.body}");

      final res = jsonDecode(response.body);
      if (res['status'] == 'success') {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Success: $newStatus")));
        setState(() => isScanning = true);
      } else {
        print("DEBUG: Update failed according to server logic: ${res['message']}");
      }
    } catch (e) {
      print("DEBUG: Network/Catch Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Failed")));
    }
  }
  // --- TAB 2: HISTORY LOGIC ---

  Future<void> _fetchGateHistory() async {
    setState(() => isHistoryLoading = true);
    try {
      // Centralized script doesn't need target_db anymore
      final response = await http.get(Uri.parse("${AppConstants.getverifyPassUrl}/get_gate_history.php"));
      if (response.statusCode == 200) {
        setState(() => history = json.decode(response.body));
      }
    } catch (e) {
      debugPrint("History Error: $e");
    } finally {
      setState(() => isHistoryLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gate Security",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
          backgroundColor: const Color(0xFF800000),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
            onTap: (index) { if (index == 1) _fetchGateHistory(); },
            labelColor: Colors.white, // Ensures the selected label/icon is white
            unselectedLabelColor: Colors.white70, // Ensures unselected icons are a slightly faded white
            tabs: const [
              Tab(
                  text: "Scanner",
                  icon: Icon(Icons.qr_code_scanner, color: Colors.white) // Forced white
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildScannerView(),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            if (isScanning && capture.barcodes.isNotEmpty) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) verifyPass(barcode.rawValue!);
            }
          },
        ),
        _buildScannerOverlay(),
      ],
    );
  }


  // --- UI HELPER: DIALOG ---
  void _showResultDialog(dynamic result) {
    String dbStatus = result['db_status'] ?? '';
    String apiStatus = result['status'] ?? '';

    Color themeColor = Colors.red;
    String message = "INVALID PASS";

    if (apiStatus == "Verified") {
      themeColor = Colors.green;
      message = (dbStatus == "LEFT CAMPUS") ? "DEPARTURE RECORDED" : "ENTRY RECORDED";
    } else if (dbStatus == "RETURNED") {
      themeColor = Colors.orange;
      message = "PASS ALREADY USED";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text("New Status: $dbStatus"),
            if (dbStatus == "RETURNED")
              const Text("\n⚠️ This pass is now expired.", style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => isScanning = true);
              },
              child: const Text("CLOSE"),
            ),
          )
        ],
      ),
    );
  }
  Widget _buildScannerOverlay() {
    return Center(
      child: Container(
        width: 250, height: 250,
        decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
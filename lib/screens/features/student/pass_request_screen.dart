import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants.dart';
import '../../../core/session_manager.dart';

class PassRequestScreen extends StatefulWidget {
  const PassRequestScreen({super.key});

  @override
  State<PassRequestScreen> createState() => _PassRequestScreenState();
}

class _PassRequestScreenState extends State<PassRequestScreen> {
  // --- VISUAL THEME CONSTANTS ---
  static const Color primaryMaroon = Color(0xFF5D1F1A);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color softCream = Color(0xFFFDF7F0);
  static const Color cardWhite = Colors.white;

  List userPasses = [];
  bool isPageLoading = true;
  bool isSubmitting = false;

  final List<String> filters = ['All', 'Pending', 'Approved', 'Rejected'];
  String selectedFilter = 'All';

  String selectedPopupPassType = 'City Pass';
  DateTime selectedDate = DateTime.now();
  DateTime returnDate = DateTime.now();
  TimeOfDay outTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay inTime = const TimeOfDay(hour: 18, minute: 0);
  final TextEditingController _reasonController = TextEditingController();
  PlatformFile? pickedFile;

  @override
  void initState() {
    super.initState();
    fetchUserPasses();
  }

  Future<void> fetchUserPasses() async {
    setState(() => isPageLoading = true);
    try {
      String? userId = await SessionManager.getUserId();
      String? targetDb = await SessionManager.getSelectedDb();
      final response = await http.get(Uri.parse("${AppConstants.getpassUrl}?user_id=$userId&target_db=${targetDb ?? 'gmu'}"));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('passes')) {
          userPasses = decoded['passes'];
        } else {
          userPasses = decoded;
        }
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => isPageLoading = false);
    }
  }

  Future<void> _pickDocument(StateSetter setModalState) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'pdf', 'png', 'jpeg'],
      );
      if (result != null && result.files.single.path != null) {
        setModalState(() => pickedFile = result.files.first);
      }
    } catch (e) {
      debugPrint("File picking error: $e");
    }
  }

  String formatDateTime(DateTime date, TimeOfDay time) {
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }

  String formatDateOnly(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _submitPassRequest() async {
    if (_reasonController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a valid reason")));
      return;
    }

    DateTime actualInDate = returnDate;
    if (selectedPopupPassType == 'City Pass') {
      selectedDate = DateTime.now();
      actualInDate = selectedDate;
      if (inTime.hour > 18 || (inTime.hour == 18 && inTime.minute > 0)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("City Pass return time cannot be after 6:00 PM")));
        return;
      }
    }

    DateTime departure = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, outTime.hour, outTime.minute);
    DateTime arrival = DateTime(actualInDate.year, actualInDate.month, actualInDate.day, inTime.hour, inTime.minute);

    if (arrival.isBefore(departure) || arrival.isAtSameMomentAs(departure)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("In-time must be after out-time")));
      return;
    }

    if (selectedPopupPassType == 'Special Pass' && pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Supporting document required for Special Pass")));
      return;
    }

    setState(() => isSubmitting = true);
    try {
      String? studentId = await SessionManager.getUserId();
      String? studentName = await SessionManager.getUserName();
      String? targetDb = await SessionManager.getSelectedDb();
      String? hostel = await SessionManager.getHostel();
      String? block = await SessionManager.getBlock();
      String? floor = await SessionManager.getFloor();
      String? parentMobile = await SessionManager.getParentMobile();

      var request = http.MultipartRequest('POST', Uri.parse(AppConstants.passrequestUrl));
      request.fields['user_id'] = studentId ?? "";
      request.fields['user_name'] = studentName ?? "Student";
      request.fields['target_db'] = targetDb ?? "gmit_new";
      request.fields['hostel'] = hostel ?? "";
      request.fields['block'] = block ?? "";
      request.fields['floor'] = floor ?? "";
      request.fields['pass_type'] = selectedPopupPassType;
      request.fields['date'] = formatDateOnly(selectedDate);
      request.fields['return_date'] = formatDateOnly(actualInDate);
      request.fields['out_date_time'] = formatDateTime(selectedDate, outTime);
      request.fields['in_date_time'] = formatDateTime(actualInDate, inTime);
      request.fields['reason'] = _reasonController.text.trim();
      request.fields['parent_mobile'] = parentMobile ?? "";
      request.fields['status'] = "Pending";

      if (pickedFile != null && pickedFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath('document', pickedFile!.path!));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Your pass request is submitted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
        _reasonController.clear();
        pickedFile = null;
        fetchUserPasses();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to submit request. Status: ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Submit Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List filteredPasses = userPasses.where((pass) {
      if (selectedFilter == 'All') return true;
      return pass['STATUS'] == selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: softCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("GATE PASS HUB",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18)),
        backgroundColor: primaryMaroon,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: RefreshIndicator(
        onRefresh: fetchUserPasses,
        color: primaryMaroon,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome back,", style: TextStyle(fontSize: 16, color: Colors.brown)),
              const Text("Your Gate Passes", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryMaroon)),
              const SizedBox(height: 25),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: primaryMaroon.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGold,
                    foregroundColor: primaryMaroon,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _showRequestBottomSheet(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, size: 22),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          "NEW PASS REQUEST",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),
              _buildModernFilters(),
              const SizedBox(height: 20),
              if (isPageLoading)
                const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: primaryMaroon)))
              else if (filteredPasses.isEmpty)
                _buildEmptyState()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredPasses.length,
                  itemBuilder: (context, index) => _buildModernPassCard(filteredPasses[index]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          bool isSelected = selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? primaryMaroon : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isSelected ? primaryMaroon : Colors.grey.shade300),
                boxShadow: isSelected ? [BoxShadow(color: primaryMaroon.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModernPassCard(Map<String, dynamic> pass) {
    Color statusColor;
    IconData statusIcon;
    final String currentStatus = (pass['STATUS'] ?? 'PENDING').toString();
    final String statusLower = currentStatus.toLowerCase().trim();

    switch (currentStatus) {
      case 'Approved':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle;
        break;
      case 'Rejected':
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.access_time_filled;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: statusColor.withOpacity(0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            currentStatus.toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pass['PASS_TYPE'] ?? 'City Pass',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryMaroon)),
                        const SizedBox(height: 10),
                        _rowInfo(Icons.calendar_today_outlined, "Out: ${pass['DATE']}"),
                        const SizedBox(height: 5),
                        if (pass['RETURN_DATE'] != null && pass['RETURN_DATE'] != pass['DATE'])
                          _rowInfo(Icons.keyboard_return_rounded, "Return: ${pass['RETURN_DATE']}"),
                        const SizedBox(height: 5),
                        Text(pass['REASON'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                  ),
                  if (statusLower == 'approved' || statusLower == 'left campus')
                    GestureDetector(
                      onTap: () => _showQRCode(pass),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: softCream,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: accentGold.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: primaryMaroon, size: 35),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.history_edu_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text("No passes found", style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
        ],
      ),
    );
  }

  void _showRequestBottomSheet(BuildContext context) {
    selectedDate = DateTime.now();
    if (selectedPopupPassType == 'City Pass') returnDate = selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 15, left: 25, right: 25),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 25),
                const Text("REQUEST NEW PASS", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryMaroon, letterSpacing: 1)),
                const SizedBox(height: 30),
                _buildModernInputLabel("Pass Type"),
                _buildModernDropdown(setModalState),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimePicker(
                        label: "Date Out",
                        value: DateFormat('dd MMM yyyy').format(selectedDate),
                        onTap: selectedPopupPassType == 'City Pass'
                            ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("City Pass is only available for today")))
                            : () async {
                                final dt = await showDatePicker(
                                    context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2027));
                                if (dt != null) {
                                  setModalState(() {
                                    selectedDate = dt;
                                    if (returnDate.isBefore(dt)) returnDate = dt;
                                  });
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 15),
                    if (selectedPopupPassType != 'City Pass')
                      Expanded(
                        child: _buildDateTimePicker(
                          label: "Return Date",
                          value: DateFormat('dd MMM yyyy').format(returnDate),
                          onTap: () async {
                            final dt = await showDatePicker(
                                context: context, initialDate: returnDate, firstDate: selectedDate, lastDate: DateTime(2027));
                            if (dt != null) setModalState(() => returnDate = dt);
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimePicker(
                        label: "Out Time",
                        value: outTime.format(context),
                        onTap: () async {
                          final tm = await showTimePicker(context: context, initialTime: outTime);
                          if (tm != null) setModalState(() => outTime = tm);
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildDateTimePicker(
                        label: "In Time",
                        value: inTime.format(context),
                        onTap: () async {
                          final tm = await showTimePicker(context: context, initialTime: inTime);
                          if (tm != null) setModalState(() => inTime = tm);
                        },
                      ),
                    ),
                  ],
                ),
                if (selectedPopupPassType == 'City Pass' && (inTime.hour > 18 || (inTime.hour == 18 && inTime.minute > 0)))
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text("⚠️ Return time for City Pass must be 6:00 PM or earlier.",
                        style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 20),
                if (selectedPopupPassType == 'Special Pass') ...[
                  _buildModernInputLabel("Supporting Document (Required)"),
                  GestureDetector(
                    onTap: () => _pickDocument(setModalState),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: pickedFile == null ? Colors.grey.shade300 : primaryMaroon),
                      ),
                      child: Row(
                        children: [
                          Icon(pickedFile == null ? Icons.upload_file : Icons.check_circle,
                              color: pickedFile == null ? Colors.grey : Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              pickedFile?.name ?? "Upload proof (PDF, JPG, PNG)",
                              style: TextStyle(
                                color: pickedFile == null ? Colors.grey.shade600 : Colors.black,
                                fontWeight: pickedFile == null ? FontWeight.normal : FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pickedFile != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.red),
                              onPressed: () => setModalState(() => pickedFile = null),
                            )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildModernInputLabel("Reason for Leave (Mandatory)"),
                TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: _inputStyle("Reason for requesting pass"),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryMaroon,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: isSubmitting ? null : _submitPassRequest,
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SUBMIT REQUEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 13)),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(18),
    );
  }

  Widget _buildDateTimePicker({required String label, required String value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernInputLabel(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 18, color: primaryMaroon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown(StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedPopupPassType,
          items: ['City Pass', 'Home Pass', 'Special Pass']
              .map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold))))
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setModalState(() {
                selectedPopupPassType = newValue;
                if (newValue == 'City Pass') returnDate = selectedDate;
              });
            }
          },
        ),
      ),
    );
  }

  void _showQRCode(Map<String, dynamic> pass) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("VERIFICATION QR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: primaryMaroon)),
              const SizedBox(height: 25),
              QrImageView(data: "PASS_ID:${pass['ID']}", size: 200, foregroundColor: primaryMaroon),
              const SizedBox(height: 25),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CLOSE", style: TextStyle(color: accentGold, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io'; // Required for Platform check
import 'package:device_info_plus/device_info_plus.dart'; // Required for SSAID
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Required for Debug check
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../core/session_manager.dart';
import '../../core/constants.dart';
import '../dashboards/generic_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  /// Helper to get the real Device ID (SSAID for Android)
  Future<String> _getDeviceID() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // The unique hardware ID
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "ios_unknown";
    }
    return "unsupported_platform";
  }

  void _handlePasswordHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: const Text("Please contact the hostel administration or your warden to reset your login credentials."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Secret Debug Dialog triggered by Long Press on Logo
  void _showDebugDialog(String ssaid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("System Debug Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Device SSAID:", style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(ssaid),
            const SizedBox(height: 10),
            const Text("API Key Loaded:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(dotenv.env['API_KEY'] != null ? "✅ Yes" : "❌ No"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both username and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic>? result = await AuthService.login(
          _userController.text.trim(),
          _passController.text.trim(),
          ""
      );

      setState(() => _isLoading = false);

      if (result != null && result['status'] == 'success') {
        final Map<String, dynamic> userData = Map<String, dynamic>.from(result['user']);
        String dbName = result['db_name'] ?? 'default_db';

        // 1. Map the role first
        String rawRole = (result['role'] ?? userData['designation'] ?? 'student')
            .toString()
            .toLowerCase();

        String finalRole = 'student';
        if (rawRole.contains('supervisor')) {
          finalRole = 'supervisor';
        } else if (rawRole.contains('manager') || rawRole.contains('office')) {
          finalRole = 'manager';
        } else if (rawRole.contains('security')) {
          finalRole = 'security';
        }

        // 2. Add the mapped role to the userData map so SessionManager saves it
        userData['USER_GROUP'] = finalRole;

        // 3. Save Session
        await SessionManager.saveUserSession(userData, dbName);

        if (mounted) {
          // 4. Navigate using your named routes (defined in main.dart)
          // passing the finalRole as an argument to the /dashboard route
          Navigator.pushReplacementNamed(
            context,
            '/dashboard',
            arguments: finalRole,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?['message'] ?? "Invalid Credentials")),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gmMaroon = Color(0xFF5D1F1A);

    // Returning a Scaffold here is the "Safety Net" for the No Material Error
    return Scaffold(
      backgroundColor: Colors.transparent, // Keeps the Splash Screen's cream color
      body: Padding(
        padding: const EdgeInsets.fromLTRB(35, 10, 35, 0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. Handlebar
              const SizedBox(height: 10), // Padding from top
              Container(
                width: 45, height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 25),

              // 2. Centered Login Tab
              Column(
                children: [
                  const Text("Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(height: 3, width: 30, color: gmMaroon),
                ],
              ),
              const SizedBox(height: 35),

              // 3. Inputs
              _buildLoginTextField(
                controller: _userController,
                hint: "Username / USN",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildLoginTextField(
                controller: _passController,
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              if (AppConstants.isForgotPasswordEnabled)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handlePasswordHelp(context),
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 40),

              // 4. Button
              _isLoading
                  ? const CircularProgressIndicator(color: gmMaroon)
                  : SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gmMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _handleLogin,
                  child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildLoginTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8), // Very light grey background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontSize: 18, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          prefixIcon: Icon(icon, color: Colors.black87, size: 24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

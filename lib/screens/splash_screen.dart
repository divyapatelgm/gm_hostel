import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboards/generic_dashboard.dart';
import 'auth/login_screen.dart';
import '../../core/session_manager.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showLoginPanel = false;

  @override
  void initState() {
    super.initState();
    _handleStartUp();
  }

  void _handleStartUp() async {
    await Future.delayed(const Duration(seconds: 2));

    bool loggedIn = await SessionManager.isLoggedIn();

    if (loggedIn) {
      String? role = await SessionManager.getUserGroup();
      if (!mounted) return;

      if (role != null && role.isNotEmpty) {
        // Direct everyone to the GenericDashboard and pass the role
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: role.toLowerCase(),
        );
      } else {
        // If role is missing for some reason, go to login
        setState(() => _showLoginPanel = true);
      }
    } else {
      if (!mounted) return;
      setState(() => _showLoginPanel = true);
    }
  }
  @override
  Widget build(BuildContext context) {
    // This color MUST be used in both the panel and the gradient for the blend to work
    const Color panelBg = Color(0xFFF2EFE9);
    const Color goldColor = Color(0xFFD4AF37);
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * 0.60;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: panelBg,
      body: Stack(
        children: [
          // 1. IMAGE STACK WITH BLENDING OVERLAY
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutQuart,
            top: 0,
            left: 0,
            right: 0,
            height: _showLoginPanel ? screenHeight * 0.45 : screenHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/college_photo.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // THE BLENDER: This gradient makes the image melt into the panel
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 0.9, 1.0], // Controls the "fade" points
                        colors: [
                          Colors.black.withOpacity(0.3), // Darker at top for text contrast
                          Colors.transparent,             // Clear in the middle
                          panelBg.withOpacity(0.8),      // Start of the blend
                          panelBg,                        // Solid cream at the very bottom
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. THE LOGIN PANEL (Starts exactly where the image fade ends)
          // 2. THE LOGIN PANEL
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutQuart,
            bottom: _showLoginPanel ? 0 : -panelHeight,
            left: 0,
            right: 0,
            child: Container(
              height: panelHeight,
              decoration: const BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              // Use a ClipRRect to ensure the internal Scaffold doesn't bleed over the rounded corners
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                child: const LoginScreen(),
              ),
            ),
          ),
          // 3. LOGO & TEXT
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutQuart,
            top: _showLoginPanel ? screenHeight * 0.15 : screenHeight * 0.35,
            left: 0,
            right: 0,
            child: AnimatedScale(
              scale: _showLoginPanel ? 0.75 : 1.0,
              duration: const Duration(milliseconds: 1000),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: goldColor, width: 2.5),
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/hostel_logo.jpeg',
                        height: 100,
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "GM GROUP OF HOSTELS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
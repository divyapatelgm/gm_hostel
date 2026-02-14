import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/session_manager.dart';
import '../splash_screen.dart';

class GenericDashboard extends StatefulWidget {
  final String role;
  const GenericDashboard({required this.role, super.key});

  @override
  State<GenericDashboard> createState() => _GenericDashboardState();
}

class _GenericDashboardState extends State<GenericDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _sidebarOpen = false;

  // Theme Colors
  final Color primaryColor = const Color(0xFF5D1F1A); // GM Maroon
  final Color sidebarBg = const Color(0xFF5D1F1A);
  final Color accentColor = const Color(0xFFE2B458); // GM Gold
  final Color lightBackground = const Color(0xFFF8F6F3);
  final Color cardBackground = const Color(0xFFFFFFFF);
  final Color textPrimary = const Color(0xFF2C1810);

  final Map<String, List<Map<String, dynamic>>> roleData = {
    'student': [
      {'title': 'Profile', 'icon': Icons.person_outline, 'route': '/profile', 'gradient': [const Color(0xFF5b1f1f), const Color(0xFF8b3f3f)]},
      {'title': 'Outing Pass', 'icon': Icons.vignette_outlined, 'route': '/pass_request', 'gradient': [const Color(0xFF5b1f1f), const Color(0xFF7b2f2f)]},
      {'title': 'Grievance', 'icon': Icons.feedback_outlined, 'route': '/grievances', 'gradient': [const Color(0xFFe2b458), const Color(0xFFecb858)]},
      {'title': 'Fee Payment', 'icon': Icons.payments_outlined, 'route': '/fee_payment', 'gradient': [const Color(0xFF5b1f1f), const Color(0xFF6b2f2f)]},
    ],
    'manager': [
      {'title': 'Profile', 'icon': Icons.person_outline, 'route': '/profile', 'gradient': [const Color(0xFF5b1f1f), const Color(0xFF8b3f3f)]},
      {'title': 'Mess Polls', 'icon': Icons.poll_outlined, 'route': '/manager_mess_poll', 'gradient': [const Color(0xFFe2b458), const Color(0xFFf2d478)]},
      {'title': 'Update Menu', 'icon': Icons.restaurant_menu_outlined, 'route': '/supervisor_menu_update', 'gradient': [const Color(0xFF5b1f1f), const Color(0xFF7b2f2f)]},
    ],
    'supervisor': [
      {'title': 'Profile', 'icon': Icons.person_outline, 'route': '/profile', 'gradient': [const Color(0xFF5b1f1f), const Color(0xFF8b3f3f)]},
      {'title': 'Post Notice', 'icon': Icons.add_alert_outlined, 'route': '/supervisor_notices', 'gradient':[const Color(0xFF5b1f1f), const Color(0xFF8b3f3f)]},
      {'title': 'Manage Pass', 'icon': Icons.confirmation_number_outlined, 'route': '/supervisor_pass', 'gradient': [const Color(0xFFe2b458), const Color(0xFFf2d478)]},
      {'title': 'Grievance', 'icon': Icons.report_problem_outlined, 'route': '/supervisor_grievance', 'gradient': [const Color(0xFF5b1f1f), const Color(0xFF8b3f3f)]},
    ],
    'security': [
      {'title': 'Profile', 'icon': Icons.person_outline, 'route': '/profile', 'gradient': [const Color(0xFF5b1f1f), const Color(0xFF8b3f3f)]},
      {'title': 'Scan QR', 'icon': Icons.qr_code_scanner_rounded, 'route': '/security_scanner', 'gradient': [const Color(0xFF5b1f1f), const Color(0xFF8b3f3f)]},
      {'title': 'Gate Logs', 'icon': Icons.history_edu_rounded, 'route': '/gate_logs', 'gradient': [const Color(0xFF5b1f1f), const Color(0xFF8b3f3f)]},
    ],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> gridItems = (roleData[widget.role.toLowerCase()] ?? [])
        .where((item) => item['title'] != 'Profile')
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: lightBackground,
            child: Column(
              children: [
                _buildCustomAppBar(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(), // New Welcome Header
                          const SizedBox(height: 25),
                          _buildResponsiveGrid(gridItems),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_sidebarOpen)
            GestureDetector(
              onTap: () => setState(() => _sidebarOpen = false),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          _buildSidebar(gridItems),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _sidebarOpen = !_sidebarOpen),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/hostel_logo.jpeg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.home_work, color: primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'GM GROUP OF HOSTELS',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                onPressed: () => Navigator.pushNamed(context, '/student_notices'),
              ),
              Positioned(
                right: 12, top: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return FutureBuilder<String?>(
      // Fetches the name from your session
      future: SessionManager.getUserName(),
      builder: (context, snapshot) {
        // Use the fetched name, or default to the Role if it's still loading
        String displayName = snapshot.data ?? "${widget.role[0].toUpperCase()}${widget.role.substring(1)}";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back,",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayName, // Now shows the actual user name
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebar(List<Map<String, dynamic>> menuItems) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: _sidebarOpen ? 0 : -260,
      top: 0, bottom: 0, width: 260,
      child: Container(
        color: sidebarBg,
        child: Column(
          children: [
            FutureBuilder(
              future: Future.wait([SessionManager.getUserName(), SessionManager.getUserGroup()]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                String name = snapshot.data?[0] ?? "User";
                String displayRole = snapshot.data?[1] ?? widget.role;
                return InkWell(
                  onTap: () {
                    setState(() => _sidebarOpen = false);
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.1)),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 25, backgroundColor: Colors.white, child: Icon(Icons.person, color: primaryColor, size: 30)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(displayRole.toUpperCase(), style: GoogleFonts.inter(color: accentColor, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              const Text("View Profile >", style: TextStyle(color: Colors.white54, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(color: Colors.white12, thickness: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: menuItems.map((item) => ListTile(
                  leading: Icon(item['icon'], color: Colors.white70, size: 22),
                  title: Text(item['title'], style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                  onTap: () {
                    setState(() => _sidebarOpen = false);
                    Navigator.pushNamed(context, item['route']);
                  },
                )).toList(),
              ),
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.white70),
              title: Text('Logout', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () async {
                await SessionManager.logout();
                if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) =>  SplashScreen()), (route) => false);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(List<Map<String, dynamic>> menuItems) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final Color themeColor = item['gradient'][0];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, item['route']),
          child: Container(
            decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(top: 0, left: 0, right: 0, height: 4, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: item['gradient'])))),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(item['icon'], color: themeColor, size: 22)
                      ),
                      const SizedBox(height: 8),
                      Text(item['title'], textAlign: TextAlign.center, style: GoogleFonts.inter(color: textPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
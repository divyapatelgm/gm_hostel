import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboards/generic_dashboard.dart';
import 'screens/features/profile_screen.dart';
// import 'screens/features/room_change_request.dart';
import 'screens/features/student/pass_request_screen.dart';
import 'screens/features/supervisor/supervisor_pass_screen.dart';
import 'screens/features/student/mess_menu_screen.dart';
import 'screens/features/student/fee_payment_screen.dart';
import 'screens/features/student/grievances_screen.dart';
import 'screens/features/security/security_scanner.dart';
// import 'screens/features/supervisor_room_request.dart';
import 'screens/features/manager/manager_room_approval.dart';
import 'screens/features/student/room_info_screen.dart';
import 'screens/features/supervisor/supervisor_grievance_screen.dart';
import 'screens/features/manager/manager_mess_poll_screen.dart';
import 'package:hostel/screens/features/supervisor/supervisor_menu_update_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/features/student/student_notices_screen.dart';
import 'screens/features/supervisor/supervisor_notice_screen.dart';
import 'screens/features/security/gate_logs_screen.dart';


Future<void> main() async {
  // 1. Required for SharedPreferences/Plugins/DotEnv to work before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load the environment file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: Could not load .env file: $e");
  }

  runApp(const HostelApp());
}

class HostelApp extends StatelessWidget {
  const HostelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hostel Management System',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) =>  SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) {
          // Retrieve the role passed via arguments
          final role = ModalRoute.of(context)!.settings.arguments as String;
          return GenericDashboard(role: role);
        },
        '/profile': (context) => const ProfileScreen(),
        // '/room_change': (context) => const RoomChangeRequestScreen(),
        '/room_info': (context) =>  RoomInfoScreen(),
        // '/room_change_request': (context) => const RoomChangeRequestScreen(),
        '/pass_request': (context) => const PassRequestScreen(),
        '/supervisor_pass': (context) =>  SupervisorPassScreen(),
        '/student_notices': (context) => const StudentNoticeScreen(),
        '/supervisor_notices': (context) => const SupervisorNoticeScreen(),
        // '/supervisor_room_request': (context) => const SupervisorRoomApprovalScreen(),
        '/manager_room_approval': (context) => const ManagerRoomApprovalScreen(),
        '/mess_menu': (context) => const MessMenuScreen(),
        '/supervisor_menu_update': (context) => const AdminMenuUpdateScreen(),
        '/fee_payment': (context) => const FeePaymentScreen(),
        '/grievances': (context) =>  StudentGrievanceScreen(),
        '/supervisor_grievance': (context) => const SupervisorGrievanceScreen(),
        '/security_scanner': (context) => const SecurityScanner(),
        '/gate_logs': (context) => const GateLogsScreen(),
        '/manager_mess_poll': (context) => const ManagerMessPollScreen(),
      },
    );
  }
}

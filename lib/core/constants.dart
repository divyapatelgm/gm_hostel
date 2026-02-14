
class AppConstants {
  static const String ip = "172.21.2.173";
  static const String port = "80";
  static const String baseUrl = "http://$ip:$port/hostel_backend";
  static const String loginUrl = "$baseUrl/login.php";
  static const String profileUrl = "$baseUrl/get_profile.php";
  static const String passrequestUrl = "$baseUrl/save_pass.php";
  static const String getpassUrl = "$baseUrl/get_all_passes.php";
  static const String getStudentPassesUrl = "$baseUrl/get_student_passes.php";
  static const String updatePassUrl = "$baseUrl/update_pass_status.php";
  static const String verifyPass = "$baseUrl/verify_gate_pass.php";
  static const String grievanceUrl = "$baseUrl/submit_grievance.php";
  static const String getAllGrievancesUrl = "$baseUrl/get_all_grievances.php";
  static const String getverifyPassUrl = "$baseUrl/get_gate_history.php";
  static const String solveGrievanceUrl = "$baseUrl/update_grievance_status.php";
  static const String getnoticesUrl = "$baseUrl/get_notices.php";
  static const String postnoticeUrl = "$baseUrl/post_notices.php";
  static const bool isForgotPasswordEnabled = true;
  // Logic toggle: true = send to DB, false = just show alert
  static const bool isNotificationBackendReady = false;



}
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  // Key Constants
  static const String _keySlNo        = "sl_no";
  static const String _keyId          = "id";
  static const String _keyName        = "name";
  static const String _keyMobile      = "mobile_no";
  static const String _keyUsername    = "username";
  static const String _keyDesignation = "designation";
  static const String _keyUserGroup   = "user_group";
  static const String _keyIsLoggedIn  = "is_logged_in";
  static const String _keyDbName      = "selected_db";
  static const String _keyHostel      = "hostel";
  static const String _keyBlock       = "block";
  static const String _keyFloor       = "floor";
  static const String _keyParentMobile = "parent_mobile";

  /// 1. Save Full User Session with SMART MERGE
  static Future<void> saveUserSession(Map<String, dynamic> userData, String dbName) async {
    final prefs = await SharedPreferences.getInstance();

    if (dbName.isNotEmpty) {
      await prefs.setString(_keyDbName, dbName);
    }

    // 2. PERMANENT FIX: The Smart Merge Helper
    Future<void> mergeValue(String key, dynamic newValue) async {
      // Convert to string and trim
      String value = newValue?.toString().trim() ?? '';

      // ONLY update the stored value if the new value is NOT empty.
      // This prevents "Not Assigned" from overwriting your real data.
      if (value.isNotEmpty && value != "N/A" && value != "null") {
        await prefs.setString(key, value);
      }
    }

    // Handle both Login (lowercase) and Profile (UPPERCASE) API responses
    await mergeValue(_keySlNo,        userData['SL_NO'] ?? userData['sl_no']);
    await mergeValue(_keyId,          userData['ID'] ?? userData['id']);
    await mergeValue(_keyName,        userData['NAME'] ?? userData['name']);
    await mergeValue(_keyMobile,      userData['MOBILE_NO'] ?? userData['mobile_no']);
    await mergeValue(_keyUsername,    userData['USER_NAME'] ?? userData['username']);
    await mergeValue(_keyDesignation, userData['DESIGNATION'] ?? userData['designation']);
    await mergeValue(_keyUserGroup,   userData['USER_GROUP'] ?? userData['user_group']);

    // Hostel specific details
    await mergeValue(_keyHostel,      userData['HOSTEL'] ?? userData['hostel']);
    await mergeValue(_keyBlock,       userData['BLOCK'] ?? userData['block']);
    await mergeValue(_keyFloor,       userData['FLOOR'] ?? userData['floor']);

    // Note: Parent Mobile check for both common key formats
    await mergeValue(_keyParentMobile, userData['PARENT_MOBILE'] ?? userData['parent_mobile']);

    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// 2. Getters (Standardized)
  static Future<String?> _getString(String key) async => (await SharedPreferences.getInstance()).getString(key);

  static Future<String?> getSlNo() async => _getString(_keySlNo);
  static Future<String?> getUserId() async => _getString(_keyId);
  static Future<String?> getUserName() async => _getString(_keyName);
  static Future<String?> getUserGroup() async => _getString(_keyUserGroup);
  static Future<String?> getHostel() async => _getString(_keyHostel);
  static Future<String?> getBlock()  async => _getString(_keyBlock);
  static Future<String?> getFloor()  async => _getString(_keyFloor);
  static Future<String?> getSelectedDb() async => _getString(_keyDbName);
  static Future<String?> getParentMobile() async => _getString(_keyParentMobile);
  static Future<String?> getDesignation() async => _getString(_keyDesignation);
  static Future<String?> getUsername() async => _getString(_keyUsername);
  static Future<String?> getMobile() async => _getString(_keyMobile);



  /// static
  /// 3. Auth Controls
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep the DB name, but clear user info
    String? savedDb = prefs.getString(_keyDbName);
    await prefs.clear();
    if (savedDb != null) {
      await prefs.setString(_keyDbName, savedDb);
    }
    await prefs.setBool(_keyIsLoggedIn, false);
  }}
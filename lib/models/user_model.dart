class UserModel {
  final String id;
  final String username;
  final String role;

  UserModel({required this.id, required this.username, required this.role});

  // Convert JSON from PHP into a Dart Object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'].toString(),
      username: json['username'] ?? '',
      role: json['designation'] ?? '', // Updated: Role is in 'designation' column
    );
  }
}
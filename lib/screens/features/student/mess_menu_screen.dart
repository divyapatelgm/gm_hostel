import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import '../../../core/constants.dart';
import '../../../core/session_manager.dart';
import '../../../core/app_theme.dart';

class MessMenuScreen extends StatefulWidget {
  const MessMenuScreen({super.key});

  @override
  State<MessMenuScreen> createState() => _MessMenuScreenState();
}

class _MessMenuScreenState extends State<MessMenuScreen> {
  bool isLoading = true;
  int _userRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  List<String> menuImages = []; // URLs from the server

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // Fetching only the menu images uploaded by the supervisor
      final response = await http.get(Uri.parse("${AppConstants.baseUrl}/get_menu_images.php"));
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          menuImages = List<String>.from(data['images']);
        });
      }
    } catch (e) {
      debugPrint("Data Fetch Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mess Bulletin'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: PHOTO MENU ---
              _buildSectionHeader("Today's Menu"),
              const SizedBox(height: 12),
              _buildMenuImageSection(),

              const SizedBox(height: 40),

              // --- SECTION 2: ENHANCED FEEDBACK ---
              _buildSectionHeader("Share Your Feedback"),
              const SizedBox(height: 8),
              const Text(
                "Your comments go directly to the supervisor for quality control.",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildEnhancedFeedbackCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuImageSection() {
    if (menuImages.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 50),
            SizedBox(height: 10),
            Text("No menu photo posted yet", style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }
    return SizedBox(
      height: 350, // Larger height for better readability of text in photos
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: menuImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                menuImages[index],
                width: MediaQuery.of(context).size.width * 0.85,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator(color: AppTheme.accent));
                },
                errorBuilder: (c, e, s) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white24, size: 40),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text("Rating", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => _userRating = index + 1),
                icon: Icon(
                  index < _userRating ? Icons.star : Icons.star_border,
                  color: Colors.amber, size: 40,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Tell us about the quality, taste, or cleanliness...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _submitFeedback,
              child: const Text("SUBMIT REVIEW", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a star rating")));
      return;
    }

    try {
      final studentId = await SessionManager.getUserId();
      final response = await http.post(
        Uri.parse("${AppConstants.baseUrl}/submit_detailed_feedback.php"),
        body: {
          "student_id": studentId,
          "rating": _userRating.toString(),
          "description": _feedbackController.text,
          "meal_type": _getAutoMealType(),
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you! Feedback sent.")));
        setState(() {
          _userRating = 0;
          _feedbackController.clear();
        });
      }
    } catch (e) {
      debugPrint("Feedback Error: $e");
    }
  }

  String _getAutoMealType() {
    int hour = DateTime.now().hour;
    if (hour < 11) return "Breakfast";
    if (hour < 16) return "Lunch";
    if (hour < 19) return "Snacks";
    return "Dinner";
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white));
  }

  Widget _buildLoadingState() {
    return Center(
      child: Lottie.asset('assets/animations/cooking_pot.json', width: 180),
    );
  }
}
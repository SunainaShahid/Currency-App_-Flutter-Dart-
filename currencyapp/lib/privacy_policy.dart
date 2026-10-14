import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Navy Blue Theme Colors
    const Color navyBlue = Color(0xFF1A237E);
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    Color cardColor = isDarkMode ? Colors.white10 : Colors.white;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
              
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Privacy Policy",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.blue.shade300 : navyBlue,
                ),
              ),
              const Divider(height: 30, thickness: 1),
              _buildPolicyText(
                "We respect your privacy. This app collects only necessary user data such as email and profile information.",
                textColor,
              ),
              const SizedBox(height: 20),
              _buildPolicyPoint("1. Data Usage", "Your data is used only for app functionality.", navyBlue, textColor, isDarkMode),
              _buildPolicyPoint("2. Data Protection", "We do not sell or share your personal data.", navyBlue, textColor, isDarkMode),
              _buildPolicyPoint("3. Security", "We use Firebase security rules to protect your data.", navyBlue, textColor, isDarkMode),
              _buildPolicyPoint("4. Changes", "Privacy policy may be updated in future.", navyBlue, textColor, isDarkMode),
              const Divider(height: 40, thickness: 1),
              Text(
                "By using this app, you agree to this policy.",
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyPoint(String title, String description, Color themeColor, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.blue.shade200 : themeColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 15, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyText(String text, Color textColor) {
    return Text(
      text,
      style: TextStyle(fontSize: 15, height: 1.5, color: textColor),
    );
  }
}
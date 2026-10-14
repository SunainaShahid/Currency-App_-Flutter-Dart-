import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  // Theme Color
  static const Color navyBlue = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text(
          "FAQs",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: navyBlue,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildFAQTile(
            "What is this app used for?",
            "This app is used to convert different currencies in real-time like USD to PKR, EUR to USD, etc.",
            isDarkMode,
          ),
          _buildFAQTile(
            "Can I convert multiple currencies?",
            "Yes, you can select any currency and convert it into another supported currency easily.",
            isDarkMode,
          ),
          _buildFAQTile(
            "Why is the conversion rate changing?",
            "Currency rates change due to global market conditions, so values may vary every moment.",
            isDarkMode,
          ),
          _buildFAQTile(
            "Is this app free to use?",
            "Yes, this app is completely free for all users.",
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: navyBlue,
          collapsedIconColor: Colors.grey,
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : navyBlue,
              fontSize: 15,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.black87,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
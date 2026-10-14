import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetails extends StatefulWidget {
  final String userId;
  const UserDetails({super.key, required this.userId});

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  bool isDeleted = false;
  static const Color navyBlue = Color(0xFF1A237E);

  Future<void> _confirmAndDelete(BuildContext context) async {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text("Delete User"),
        content: const Text("Are you sure you want to delete this user? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection("users_data")
                    .doc(widget.userId)
                    .delete();

                setState(() {
                  isDeleted = true;
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User deleted successfully")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "User Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: navyBlue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isDeleted
          ? _buildEmptyUI(isDark)
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users_data")
                  .doc(widget.userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: navyBlue));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildEmptyUI(isDark);
                }

                var data = snapshot.data!.data() as Map<String, dynamic>;
                
                Future<int> getConversionCount() async {
                  var historySnap = await FirebaseFirestore.instance
                      .collection("users_data")
                      .doc(widget.userId)
                      .collection("history")
                      .get();
                  return historySnap.docs.length;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: navyBlue.withOpacity(0.2), width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: isDark ? Colors.white10 : Colors.blue.shade50,
                            backgroundImage: (data["profile_pic"] != null && data["profile_pic"] != "")
                                ? NetworkImage(data["profile_pic"])
                                : null,
                            child: (data["profile_pic"] == null || data["profile_pic"] == "")
                                ? const Icon(Icons.person, size: 60, color: navyBlue)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _infoCard(
                        "Email Address",
                        widget.userId,
                        Icons.email_outlined,
                        navyBlue,
                        isDark,
                      ),
                      _infoCard(
                        "Total Notifications",
                        "${data['notifications_count'] ?? 0}",
                        Icons.notifications_active_outlined,
                        Colors.orange,
                        isDark,
                      ),
                      FutureBuilder<int>(
                        future: getConversionCount(),
                        builder: (context, snap) {
                          return _infoCard(
                            "Total Conversions",
                            snap.hasData ? "${snap.data}" : "Loading...",
                            Icons.swap_horizontal_circle_outlined,
                            Colors.green,
                            isDark,
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmAndDelete(context),
                          icon: const Icon(Icons.delete_forever, color: Colors.white),
                          label: const Text(
                            "REMOVE USER ACCOUNT",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyUI(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_accounts, size: 100, color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text(
              "Account No Longer Exists",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "This user data has been permanently removed from the system.",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String sub, IconData icon, Color color, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, 
          style: TextStyle(
            fontSize: 13, 
            color: isDark ? Colors.white60 : Colors.grey.shade600,
            fontWeight: FontWeight.w500
          )
        ),
        subtitle: Text(sub, 
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87
          )
        ),
      ),
    );
  }
}
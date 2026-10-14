import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currencyapp/admin/manage%20history.dart';
import 'package:currencyapp/admin/user_feedbacks.dart';
import 'package:currencyapp/login.dart';
import 'package:currencyapp/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currencyapp/admin/userdetails.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final TextEditingController rateController = TextEditingController();
  String selectedCurrency = "USD";
  
  final List<String> currencies = [
    "USD", "PKR", "EUR", "GBP", "SAR", "AED", "INR", "CAD"
  ];

  static const Color navyBlue = Color(0xFF1A237E);


  Future<void> updateCurrency() async {
    String newRate = rateController.text.trim();
    if (newRate.isEmpty) return;

    try {
      DocumentReference currencyRef =
          FirebaseFirestore.instance.collection("currency").doc(selectedCurrency);

      DocumentSnapshot snap = await currencyRef.get();
      List history = [];

      if (snap.exists) {
        var data = snap.data() as Map<String, dynamic>;
        history = data["history"] ?? [];
      }

      history.add({"rate": newRate, "time": DateTime.now().toString()});

      await currencyRef.set({
        "rate": newRate,
        "history": history,
        "updated_at": DateTime.now(),
      });

      var users = await FirebaseFirestore.instance.collection("users_data").get();

      for (var user in users.docs) {
        await FirebaseFirestore.instance
            .collection("users_data")
            .doc(user.id)
            .set({
          "notifications_count": FieldValue.increment(1),
        }, SetOptions(merge: true));
        
        await FirebaseFirestore.instance
            .collection("users_data")
            .doc(user.id)
            .collection("notifications")
            .add({
          "message": "$selectedCurrency rate updated to $newRate",
          "time": DateTime.now(),
          "read": false,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Currency + History Updated Successfully")),
      );
      rateController.clear();
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _markAsRead(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection("feedbacks")
          .doc(docId)
          .update({"status": "read"});
    } catch (e) {
      print("Error updating feedback: $e");
    }
  }

  Stream<QuerySnapshot> getUsers() {
    return FirebaseFirestore.instance.collection("users_data").snapshots();
  }

  Stream<QuerySnapshot> getFeedbacks() {
    return FirebaseFirestore.instance
        .collection("feedbacks")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: navyBlue,
        elevation: 0,
        leading: const Icon(Icons.admin_panel_settings, color: Colors.white),
        title: const Text(
          "Admin Control",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManageHistory()),
            ),
          ),
          
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'Signup') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Signup()));
              }
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text("Sign Out")),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currency Update Section
            Card(
              elevation: 4,
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("Live Rate Management", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCurrency,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          items: currencies.map((String value) {
                            return DropdownMenuItem(value: value, child: Text(value));
                          }).toList(),
                          onChanged: (val) => setState(() => selectedCurrency = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: "Enter New Rate for $selectedCurrency",
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: updateCurrency,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyBlue, 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: const Text("Push Update to Users", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            //  Users List Section
            const Text(" Registered Users", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: getUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var users = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    var data = user.data() as Map<String, dynamic>;
                    return Card(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      child: ListTile(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserDetails(userId: user.id))),
                        leading: CircleAvatar(
                          backgroundColor: navyBlue.withOpacity(0.1),
                          child: const Icon(Icons.person, color: navyBlue),
                        ),
                        title: Text(user.id, style: const TextStyle(fontSize: 14)),
                        subtitle: Text("Unread: ${data["notifications_count"] ?? 0}"),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 25),

            //  FEEDBACKS SECTION
            const Text(" User Feedbacks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: getFeedbacks(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var feedbacks = snapshot.data!.docs;
                if (feedbacks.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No feedbacks yet.")));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    var fb = feedbacks[index];
                    var data = fb.data() as Map<String, dynamic>;
                    bool isRead = data["status"] == "read";

                    return Card(
                      color: isRead 
                        ? (isDark ? const Color(0xFF1E1E1E) : Colors.white) 
                        : (isDark ? Colors.indigo.withOpacity(0.2) : Colors.blue.shade50),
                      child: ListTile(
                        title: Text(data["content"] ?? "No content", maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text("Status: ${data["status"]}"),
                        trailing: Icon(
                          isRead ? Icons.check_circle : Icons.mark_as_unread,
                          color: isRead ? Colors.green : Colors.orange,
                        ),
                        onTap: () {
                          if (!isRead) _markAsRead(fb.id);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              title: const Text("Feedback Message"),
                              content: Text(data["content"]),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}



















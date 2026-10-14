import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  final String userId;
  const NotificationsPage({super.key, required this.userId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const Color navyBlue = Color(0xFF1A237E);
  bool _isUpdated = false; 

  @override
  void initState() {
    super.initState();
  
    _handleBackgroundTasks();
  }

  void _handleBackgroundTasks() {
    if (_isUpdated) return;

  
    FirebaseFirestore.instance
        .collection("users_data")
        .doc(widget.userId)
        .update({"notifications_count": 0});

    
    FirebaseFirestore.instance
        .collection("users_data")
        .doc(widget.userId)
        .collection("notifications")
        .where("read", isEqualTo: false)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {"read": true});
        }
        batch.commit();
      }
      _isUpdated = true; 
    }).catchError((e) => print("Update Error: $e"));
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: navyBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
    
        stream: FirebaseFirestore.instance
            .collection("users_data")
            .doc(widget.userId)
            .collection("notifications")
            .orderBy("time", descending: true)
            .limit(20) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: navyBlue));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text("No notifications yet", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            itemCount: snapshot.data!.docs.length,
        
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              
              DateTime? notificationTime;
              if (data["time"] != null) notificationTime = (data["time"] as Timestamp).toDate();
              String formattedTime = notificationTime != null 
                  ? DateFormat('dd MMM, hh:mm a').format(notificationTime) 
                  : "Just now";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: navyBlue.withOpacity(0.1),
                    child: const Icon(Icons.notifications_active, color: navyBlue, size: 20),
                  ),
                  title: Text(data["message"] ?? "Notification", 
                    style: TextStyle(fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black87)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(formattedTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
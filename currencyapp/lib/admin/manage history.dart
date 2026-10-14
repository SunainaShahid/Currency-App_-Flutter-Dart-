import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageHistory extends StatefulWidget {
  const ManageHistory({super.key});

  @override
  State<ManageHistory> createState() => _ManageHistoryState();
}

class _ManageHistoryState extends State<ManageHistory> {
  String selectedCurrency = "USD";
  final List<String> currencies = ["USD", "PKR", "EUR", "GBP", "SAR", "AED", "INR", "CAD"];
  static const Color navyBlue = Color(0xFF1A237E);

  // DELETE LOGIC
  Future<void> deleteItem(int originalIndex) async {
    DocumentReference ref = FirebaseFirestore.instance.collection("currency").doc(selectedCurrency);
    DocumentSnapshot snap = await ref.get();
    List history = List.from((snap.data() as Map<String, dynamic>)["history"]);
    
    history.removeAt(originalIndex); // Original index use hoga delete ke liye
    await ref.update({"history": history});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Entry Deleted")));
    }
  }


  void showEditDialog(int originalIndex, String currentRate) {
    TextEditingController editController = TextEditingController(text: currentRate);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text("Edit Rate", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController, 
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "New Rate",
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: navyBlue)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: navyBlue),
            onPressed: () async {
              DocumentReference ref = FirebaseFirestore.instance.collection("currency").doc(selectedCurrency);
              DocumentSnapshot snap = await ref.get();
              List history = List.from((snap.data() as Map<String, dynamic>)["history"]);
              
              history[originalIndex]["rate"] = editController.text;
              history[originalIndex]["time"] = "${DateTime.now().toString()} (Edited)";
              
              await ref.update({"history": history});
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          )
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
        title: const Text("Currency History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        backgroundColor: navyBlue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: DropdownButtonFormField(
              dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              value: selectedCurrency,
              items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => selectedCurrency = val!),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.white,
                labelText: "Select Currency",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection("currency").doc(selectedCurrency).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("No Data"));
                
                List history = (snapshot.data!.data() as Map<String, dynamic>)["history"] ?? [];
                
              
                List reversedHistory = history.reversed.toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: reversedHistory.length,
                  itemBuilder: (context, index) {
                    var item = reversedHistory[index];
                    // Original index nikalne ke liye formula
                    int originalIndex = history.length - 1 - index;

                    return Card(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: navyBlue.withOpacity(0.1),
                          child: const Icon(Icons.history, color: navyBlue, size: 20),
                        ),
                        title: Text("Rate: ${item['rate']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Time: ${item['time']}", style: const TextStyle(fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.orange), 
                              onPressed: () => showEditDialog(originalIndex, item['rate'])
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red), 
                              onPressed: () => deleteItem(originalIndex)
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
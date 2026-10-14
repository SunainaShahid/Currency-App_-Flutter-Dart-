import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CurrencyHistory extends StatefulWidget {
  final String currencyName;

  const CurrencyHistory({super.key, required this.currencyName});

  @override
  State<CurrencyHistory> createState() => _CurrencyHistoryState();
}

class _CurrencyHistoryState extends State<CurrencyHistory> {
  late String selectedCurrency;
  
  final List<String> currencies = [
    "USD", "PKR", "EUR", "GBP", "SAR", "AED", "INR", "CAD"
  ];
  
  static const Color navyBlue = Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    selectedCurrency = currencies.contains(widget.currencyName) 
        ? widget.currencyName 
        : "USD";
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text(
          "Currency History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: navyBlue,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
         
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: selectedCurrency,
                dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                style: TextStyle(color: isDarkMode ? Colors.white : navyBlue, fontSize: 16),
                decoration: const InputDecoration(
                  labelText: "Select Currency",
                  labelStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                items: currencies.map((String value) {
                  return DropdownMenuItem(
                    value: value, 
                    child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedCurrency = val!;
                  });
                },
              ),
            ),
          ),

          //  History List Section 
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("currency")
                  .doc(selectedCurrency)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: navyBlue));
                }
                
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text("No Data Found for this Currency", 
                    style: TextStyle(color: Colors.grey))
                  );
                }

                var data = snapshot.data!.data() as Map<String, dynamic>;
                List history = data["history"] ?? [];
                List reversedHistory = List.from(history.reversed);

                return ListView.builder(
                  itemCount: reversedHistory.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    var item = reversedHistory[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: navyBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history, color: navyBlue, size: 22),
                        ),
                        title: Text(
                          "Rate: ${item["rate"]}", 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 17
                          )
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Date: ${item["time"]}",
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:currencyapp/admin/currency_history.dart';
import 'package:currencyapp/faqs.dart';
import 'package:currencyapp/history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currencyapp/login.dart';
import 'package:currencyapp/notification.dart';
import 'package:currencyapp/profile.dart';
import 'package:currencyapp/services/api_service.dart';
import 'package:currencyapp/services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';

class XECurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40); 
    var controlPoint = Offset(size.width / 2, size.height); 
    var endPoint = Offset(size.width, size.height - 40); 
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Color navyBlue = const Color(0xFF1A237E);
  final Color accentColor = const Color(0xFF2196F3);

  int _currentIndex = 0;
  TextEditingController amountController = TextEditingController(text: "100");
  String fromCurrency = "USD";
  String toCurrency = "PKR";
  double result = 0.0;
  bool isLoading = true;
  DatabaseService db = DatabaseService();
  Map<String, dynamic> liveRates = {};

  final Map<String, String> flags = {
    'USD': "🇺🇸", 'PKR': "🇵🇰", 'EUR': "🇪🇺", 'GBP': "🇬🇧",
    'SAR': "🇸🇦", 'AED': "🇦🇪", 'INR': "🇮🇳", 'CAD': "🇨🇦",
  };

  @override
  void initState() {
    super.initState();
    loadInitialRates();
  }

  void loadInitialRates() async {
    try {
      var rates = await ApiService.fetchRates(fromCurrency);
      if (rates.isNotEmpty && mounted) {
        setState(() {
          liveRates = rates;
          isLoading = false;
        });
        _calculateValueOnly();
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _calculateValueOnly() {
    if (liveRates.isEmpty) return;
    double amount = double.tryParse(amountController.text) ?? 0;
    double toRate = liveRates[toCurrency]?.toDouble() ?? 1.0;
    setState(() => result = amount * toRate);
  }

  void handleConversion() async {
    _calculateValueOnly();
    await db.saveConversion(
      from: fromCurrency,
      to: toCurrency,
      amount: double.tryParse(amountController.text) ?? 0,
      result: result,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved to cloud history"), duration: Duration(seconds: 1)),
    );
  }

  void swapCurrencies() {
    setState(() {
      String temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
      loadInitialRates();
    });
  }

  List<FlSpot> _generateLiveSpots() {
    double rate = liveRates[toCurrency]?.toDouble() ?? 1.0;
    return [
      FlSpot(0, rate * 0.98), FlSpot(1, rate * 1.02), FlSpot(2, rate * 0.99),
      FlSpot(3, rate * 1.04), FlSpot(4, rate * 0.97), FlSpot(5, rate * 1.01), FlSpot(6, rate),
    ];
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: navyBlue,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white.withOpacity(0.15),
            height: 1.0,
          ),
        ),
        leading: const Icon(Icons.currency_exchange, color: Colors.white, size: 26), 
        title: const Text("Currensee", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users_data')
                .doc(currentUserId)
                .collection('notifications')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => NotificationsPage(userId: currentUserId))
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: navyBlue, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'info') Navigator.push(context, MaterialPageRoute(builder: (context) => CurrencyHistory(currencyName: toCurrency)));
              if (value == 'faqs') Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQPage()));
              if (value == 'logout') {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'info', child: Text("Currency Info")),
              const PopupMenuItem(value: 'faqs', child: Text("FAQs")),
              const PopupMenuItem(value: 'logout', child: Text("Sign Out")),
            ],
          ),
        ],
      ),
      body: _currentIndex == 0
          ? (isLoading ? const Center(child: CircularProgressIndicator()) : _buildHomeBody(isDark))
          : _currentIndex == 1 ? const HistoryScreen() : const ProfilePage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: navyBlue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeBody(bool isDark) {
    return Stack(
      children: [
        ClipPath(clipper: XECurveClipper(), child: Container(height: 180, color: navyBlue)),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 15),
              const Text("Currency Converter", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Real-time exchange rates at your fingertips", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, letterSpacing: 0.5)),
              const SizedBox(height: 25),
              Card(
                elevation: 12,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      _buildCurrencyRow("From", fromCurrency, amountController, true, isDark),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Expanded(child: Divider()),
                        IconButton.filled(onPressed: swapCurrencies, icon: const Icon(Icons.swap_vert_rounded), style: IconButton.styleFrom(backgroundColor: isDark ? accentColor : navyBlue)),
                        const Expanded(child: Divider()),
                      ]),
                      const SizedBox(height: 10),
                      _buildCurrencyRow("To", toCurrency, null, false, isDark, displayValue: result.toStringAsFixed(2)),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          onPressed: handleConversion,
                          style: ElevatedButton.styleFrom(backgroundColor: navyBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          child: const Text("Convert and Save History", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),
              _buildGraphSection(isDark),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyRow(String title, String currency, TextEditingController? controller, bool isInput, bool isDark, {String? displayValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: isDark ? Colors.blueGrey[200] : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: DropdownButton<String>(
                value: currency,
                dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                underline: const SizedBox(),
                items: flags.keys.map((val) => DropdownMenuItem(value: val, child: Text("${flags[val]!} $val", style: TextStyle(color: isDark ? Colors.white : Colors.black)))).toList(),
                onChanged: (val) {
                  setState(() => isInput ? fromCurrency = val! : toCurrency = val!);
                  isInput ? loadInitialRates() : _calculateValueOnly();
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: isInput 
                ? TextField(
                    controller: controller,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: "0.00"),
                    onChanged: (val) => _calculateValueOnly(),
                  )
                : Text(displayValue ?? "0.00", textAlign: TextAlign.right, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? accentColor : navyBlue)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGraphSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Market Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.blueGrey)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.2), width: 0.5)),
              child: const Row(children: [Icon(Icons.circle, color: Colors.green, size: 8), SizedBox(width: 5), Text("LIVE", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1))]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.only(top: 20, right: 25, left: 10, bottom: 10),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (v, m) => Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(v.toInt() < days.length ? days[v.toInt()] : '', style: const TextStyle(fontSize: 10, color: Colors.grey)));
                })),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false), 
              lineBarsData: [LineChartBarData(spots: _generateLiveSpots(), isCurved: false, color: accentColor, barWidth: 3, dotData: const FlDotData(show: true), belowBarData: BarAreaData(show: true, color: accentColor.withOpacity(0.1)))],
            ),
          ),
        ),
      ],
    );
  }
}



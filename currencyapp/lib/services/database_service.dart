import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  
  Future<void> saveConversion({
    required String from,
    required String to,
    required double amount,
    required double result,
  }) async {
    try {
    
      String? uid = _auth.currentUser?.uid;
      
      if (uid == null) {
        print("Error: User not logged in");
        return;
      }

      await _db
          .collection('users_data') 
          .doc(uid) 
          .collection('history')
          .add({
        'from': from,
        'to': to,
        'amount': amount,
        'result': result,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print("History saved successfully for UID: $uid");
    } catch (e) {
      print("Firestore Save Error: $e");
    }
  }


  Stream<QuerySnapshot> getHistory() {
    String uid = _auth.currentUser?.uid ?? '';
    
    return _db
        .collection('users_data')
        .doc(uid)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Connect to the doodle ref directly
  final ref = FirebaseDatabase.instance.ref('session/current_doodle');
  print('Requesting data from Firebase RTD...');
  
  final snapshot = await ref.get();
  
  if (snapshot.exists) {
    print('DATA EXISTS in Firebase!');
    print('Raw Data length: ${(snapshot.value as List?)?.length}');
    print('First element: ${(snapshot.value as List?)?.first}');
  } else {
    print('NO DATA exactly at session/current_doodle');
  }
}

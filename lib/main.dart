import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBBTdc7Ip5a5rWLTA0_W0FrQCsmcxVWiy0",
      authDomain: "fluttergetx-4d8ae.firebaseapp.com",
      databaseURL: "https://fluttergetx-4d8ae-default-rtdb.firebaseio.com",
      projectId: "fluttergetx-4d8ae",
      storageBucket: "fluttergetx-4d8ae.firebasestorage.app",
      messagingSenderId: "759199034573",
      appId: "1:759199034573:web:ad6f06bad986e6bd950d84",
      measurementId: "G-6G78KYVTD6"
    ),
  );

  runApp(
    GetMaterialApp(
      title: 'Application',
      initialRoute: Routes.LOGIN,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:legal_case_manager/app.dart';
import 'services/notification_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Use debug for emulator/testing
  );

  // ✅ Pass the navigatorKey defined in app.dart to the Notification Service
  await NotificationService.init(navigatorKey);

  runApp(const LegalCaseApp());
}

//AIzaSyApzHnlbeLUdeszhvvyhZ3NYlCOKY53U38
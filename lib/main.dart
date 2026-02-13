import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:legal_case_manager/app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Pass the navigatorKey defined in app.dart to the Notification Service
  await NotificationService.init(navigatorKey);

  runApp(const LegalCaseApp());
}
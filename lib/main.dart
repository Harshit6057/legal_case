import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:legal_case_manager/app.dart';
import 'services/notification_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('No .env asset found. Continuing without env file. Error: $e');
    }
  }

  // 1. Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Activate App Check ONCE with both providers
  await FirebaseAppCheck.instance.activate(
    // For Android (Debug/Emulator)
    androidProvider: AndroidProvider.debug,
    // For Web (Production) - Paste your actual Site Key here
    webProvider: ReCaptchaV3Provider('6LcXyIcsAAAAAATAT2djOzEqSSrog63gu44xXsGw'),
  );

  // 3. Initialize other services
  await NotificationService.init(navigatorKey);

  // 4. Run the App
  runApp(const LegalCaseApp());
}
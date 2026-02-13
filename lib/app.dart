import 'package:flutter/material.dart';
import 'package:legal_case_manager/features/onboarding/screens/onboarding_flow_screen.dart';
import 'features/lawyer/screens/scheduled_case_detail_screen.dart';

// ✅ Define the global key that main.dart and NotificationService will use
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LegalCaseApp extends StatelessWidget {
  const LegalCaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Legal Case Manager',
      // ✅ Attach the navigatorKey here
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const OnboardingFlowScreen(),
      // ✅ Add the route generator inside the MaterialApp
      onGenerateRoute: (settings) {
        if (settings.name == '/caseDetails') {
          final caseId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => ScheduledCaseDetailScreen(caseId: caseId),
          );
        }
        return null;
      },
    );
  }
}
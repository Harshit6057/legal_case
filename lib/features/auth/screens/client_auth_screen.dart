import 'package:flutter/material.dart';
//lawyer login and signup


class ClientAuthScreen extends StatelessWidget {
  const ClientAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA),
      body: Column(
        children: [
          const Spacer(flex: 2),

          // Logo
          Image.asset(
            'assets/images/app_logo.png',
            height: 90,
          ),

          const SizedBox(height: 16),

          // App Title
          const Text(
            'JUSTICE FOR YOU',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 6),

          // Tagline
          const Text(
            'Explore the law expertly\n& with ease',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 40),

          // Bottom Green Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            decoration: const BoxDecoration(
              color: Color(0xFF22B6A8), // green shade from UI
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Login Button (White)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientAuthScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B2B45),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Signup Button (Outlined)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientAuthScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      'Signup',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

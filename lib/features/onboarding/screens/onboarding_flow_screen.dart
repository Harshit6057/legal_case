import 'package:flutter/material.dart';
import 'package:legal_case_manager/features/auth/screens/entry_choice_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  void _nextPage() {
    if (_currentIndex < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EntryChoiceScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                allowImplicitScrolling: true,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                children: const [
                  _PageOne(),
                  _PageTwo(),
                  _PageThree(),
                ],
              ),
            ),

            /// PAGE INDICATORS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => _indicator(isActive: _currentIndex == index),
              ),
            ),

            const SizedBox(height: 24),

            /// BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B2B45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _nextPage,
                  child: Text(
                    _currentIndex == 2 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  static Widget _indicator({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 26 : 10,
      height: 4,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0B2B45) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _PageOne extends StatelessWidget {
  const _PageOne();

  @override
  Widget build(BuildContext context) {
    return const _BasePage(
      image: 'assets/images/Character.png',
      text: 'Find all types of legal services in one app, with an easy process and multiple benefits.',
    );
  }
}

class _PageTwo extends StatelessWidget {
  const _PageTwo();

  @override
  Widget build(BuildContext context) {
    return const _BasePage(
      isStacked: true,
      text: 'Enter the name of your city and the type of consultant you’re looking for, and our AI bot will select the best candidate.',
    );
  }
}

class _PageThree extends StatelessWidget {
  const _PageThree();

  @override
  Widget build(BuildContext context) {
    return const _BasePage(
      image: 'assets/images/image 1.png',
      text: 'Choose the best verified lawyer profiles in your area based on qualifications, experience, and reviews.',
    );
  }
}

class _BasePage extends StatelessWidget {
  final String? image;
  final String text;
  final bool isStacked;

  const _BasePage({
    this.image,
    required this.text,
    this.isStacked = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 60),
            SizedBox(
              height: 300,
              child: isStacked
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 10,
                          right: 8,
                          child: Image.asset(
                            'assets/images/Frame (1).png',
                            width: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Image.asset(
                            'assets/images/Frame.png',
                            width: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Image.asset(
                        image!,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
            const SizedBox(height: 40),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

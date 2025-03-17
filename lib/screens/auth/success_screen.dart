import 'package:flutter/material.dart';
import '../../utils/app_styles.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/bee.png',
                height: 120,
              ),
              const SizedBox(height: 40),
              const Text(
                'Hello, I\'m Angela',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Now we can start learning!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  style: AppStyles.primaryButtonStyle,
                  child: const Text('Start learning'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

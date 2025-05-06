import 'package:baatu/screens/auth/otp_verification_screen.dart';
import 'package:flutter/material.dart';
import '../../utils/app_styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
  static const routeName = '/forgot-password';
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppStyles.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/bee.png',
                height: 120,
              ),
              const SizedBox(height: 40),
              const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Don\'t worry! It happens. Please enter the email address associated with your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: AppStyles.textFieldDecoration.copyWith(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, OtpVerificationScreen.routeName);
                  },
                  style: AppStyles.primaryButtonStyle,
                  child: const Text('Send code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

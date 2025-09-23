import 'package:baatu/screens/auth/learning_preferences_screen.dart';
import 'package:baatu/screens/navigation_home_bar.dart';
import 'package:baatu/services/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/app_styles.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
  static const String routeName = '/register_screen';
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppStyles.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.primaryColor,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: AppStyles.textFieldDecoration.copyWith(
                    hintText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: AppStyles.textFieldDecoration.copyWith(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: AppStyles.textFieldDecoration.copyWith(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: AppStyles.textFieldDecoration.copyWith(
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                if (authService.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      authService.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authService.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              // Initial preferences to store
                              Map<String, dynamic> preferences = {
                                'name': _nameController.text.trim(),
                                'registrationDate':
                                    DateTime.now().toIso8601String(),
                              };

                              bool success = await authService
                                  .registerWithEmailAndPassword(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                                preferences,
                              );

                              if (success && mounted) {
                                Navigator.pushNamed(context,
                                    LearningPreferencesScreen.routeName);
                              }
                            }
                          },
                    style: AppStyles.primaryButtonStyle,
                    child: authService.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Register'),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Text(
                    "Or",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final provider = Provider.of<GoogleSignInProvider>(
                              context,
                              listen: false);

                          final user = await provider.googleSignIn();

                          if (mounted || user?.user != null) {
                            if (user?.additionalUserInfo?.isNewUser == true) {
                              Navigator.pushNamed(
                                  context, LearningPreferencesScreen.routeName);
                            } else {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => HomeNavigationScreen()),
                                  (route) => false);
                            }
                          }
                        },
                        style: AppStyles.primaryOutlineButtonStyle,
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          color: Color(0xFF4285F4),
                        ),
                        label: const Text('Sign up with Google'),
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: AppStyles.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

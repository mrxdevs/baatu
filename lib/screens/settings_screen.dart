import 'package:baatu/screens/splash_screen.dart';
import 'package:baatu/services/auth_service.dart';
import 'package:baatu/testing_console/markdown_fomatter_screen.dart';
import 'package:baatu/testing_console/testing_screen.dart';
import 'package:baatu/utils/app_config.dart';
import 'package:baatu/utils/get_package_details.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  static const String routeName = '/settings_screen';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFF5F5F5),
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E4585).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: Color(0xFF8E4585),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Settings",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E4585),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingItem(
                          icon: Icons.notifications_outlined,
                          title: 'Reminder',
                          value: '17:00',
                          color: const Color(0xFF8E4585),
                        ),
                        _buildSettingItem(
                          icon: Icons.language_outlined,
                          title: 'Language',
                          value: 'English',
                          color: const Color(0xFF8E4585),
                        ),
                        _buildSettingItem(
                          icon: Icons.timer_outlined,
                          title: 'Lesson duration',
                          value: '20 minutes',
                          color: const Color(0xFF8E4585),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingItem(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Checkout',
                          value: '150 \$',
                          color: const Color(0xFF8E4585),
                        ),
                        _buildSettingItem(
                            icon: Icons.logout_outlined,
                            title: 'Sign out',
                            value: '',
                            color: Colors.redAccent,
                            showArrow: false,
                            onTap: () {
                              // Handle delete account action
                              AuthService().signOut();
                              Navigator.pushNamedAndRemoveUntil(context,
                                  SplashScreen.routeName, (route) => false);
                            }),
                        const SizedBox(height: 16),
                        if (AppConfig.appMode == AppMode.DEV)
                          _buildSettingItem(
                            icon: Icons.developer_mode_outlined,
                            title: 'Testing Console',
                            value: '',
                            color: Colors.green,
                            showArrow: false,
                            onTap: () {
                              Navigator.pushNamed(
                                  context, TestingScreen.routeName);
                            },
                          ),
                        SizedBox(height: 56),
                        Center(
                          child: Text(
                            'Version: ${AppPackageDetails.version ?? ""}.${AppPackageDetails.buildNumber ?? ""}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
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

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (value.isNotEmpty)
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          trailing: showArrow
              ? Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: color,
                )
              : null,
        ),
      ),
    );
  }
}

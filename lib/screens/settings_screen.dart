import 'package:baatu/screens/splash_screen.dart';
import 'package:baatu/services/auth_service.dart';
import 'package:baatu/testing_console/markdown_fomatter_screen.dart';
import 'package:baatu/testing_console/testing_screen.dart';
import 'package:baatu/utils/app_config.dart';
import 'package:baatu/utils/app_styles.dart';
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
                          onTap: () {
                            _showReminderDialog(context);
                          },
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
                          onTap: () {
                            _showLessonDurationDialog(context);
                          },
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
                          icon: Icons.workspace_premium_outlined,
                          title: 'Join',
                          value: 'Premium',
                          color: const Color(0xFF8E4585),
                          onTap: () {
                            _showSubscriptionOptions(context);
                          },
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

  // Lesson Duration Dialog
  void _showLessonDurationDialog(BuildContext context) {
    final List<int> durationOptions = [10, 15, 20, 25, 30, 45, 60];
    int selectedDuration = 20; // Default value

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppStyles.backgroundColor,
              title: const Text(
                'Set Daily Lesson Duration',
                style: TextStyle(
                  color: Color(0xFF8E4585),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Choose how much time you want to spend on lessons each day:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 200,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: durationOptions.length,
                      itemBuilder: (context, index) {
                        final duration = durationOptions[index];
                        final isSelected = duration == selectedDuration;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDuration = duration;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF8E4585).withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppStyles.backgroundColor,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$duration minutes',
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF8E4585)
                                        : Colors.black87,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF8E4585),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save the selected duration
                    // You would typically save this to your app's settings/preferences
                    Navigator.pop(context);
                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Daily lesson duration set to $selectedDuration minutes'),
                        backgroundColor: const Color(0xFF8E4585),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E4585),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Reminder Dialog
  void _showReminderDialog(BuildContext context) {
    TimeOfDay selectedTime = TimeOfDay(hour: 17, minute: 0); // Default 5:00 PM
    bool isReminderEnabled = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Set Daily Reminder',
                style: TextStyle(
                  color: Color(0xFF8E4585),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Enable daily reminder'),
                    value: isReminderEnabled,
                    activeColor: const Color(0xFF8E4585),
                    onChanged: (value) {
                      setState(() {
                        isReminderEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (isReminderEnabled)
                    Column(
                      children: [
                        const Text(
                          'Choose when you want to be reminded:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF8E4585),
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF8E4585),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8E4585),
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFF8E4585),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save the reminder settings
                    // You would typically save this to your app's settings and set up a notification
                    Navigator.pop(context);
                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isReminderEnabled
                            ? 'Daily reminder set for ${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}'
                            : 'Daily reminder disabled'),
                        backgroundColor: const Color(0xFF8E4585),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E4585),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Subscription Options Dialog
  void _showSubscriptionOptions(BuildContext context) {
    final List<Map<String, dynamic>> subscriptionPlans = [
      {
        'title': 'Daily Premium',
        'price': '₹5',
        'description': 'Full access to all premium features for one day',
        'duration': '1 day',
        'isPopular': false,
      },
      {
        'title': 'Monthly Premium',
        'price': '₹119',
        'description': 'Full access to all premium features for one month',
        'duration': '1 month',
        'isPopular': true,
      },
      {
        'title': 'Annual Premium',
        'price': '₹11199',
        'description': 'Save upto 25% with annual billing',
        'duration': '12 months',
        'isPopular': false,
      },
    ];

    int selectedPlanIndex = 1; // Default to annual plan

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppStyles.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose Your Subscription',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E4585),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Unlock all premium features and content',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: subscriptionPlans.length,
                        itemBuilder: (context, index) {
                          final plan = subscriptionPlans[index];
                          final isSelected = index == selectedPlanIndex;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPlanIndex = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF8E4585)
                                      : Colors.grey.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        plan['title'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? const Color(0xFF8E4585)
                                              : Colors.black87,
                                        ),
                                      ),
                                      if (plan['isPopular'])
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8E4585),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'POPULAR',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    plan['price'],
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xFF8E4585)
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    plan['description'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Duration: ${plan['duration']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF8E4585)
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Process subscription purchase
                          final selectedPlan =
                              subscriptionPlans[selectedPlanIndex];
                          Navigator.pop(context);
                          // Show confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Subscribing to ${selectedPlan['title']} plan'),
                              backgroundColor: const Color(0xFF8E4585),
                            ),
                          );
                          // Here you would typically integrate with your payment processor
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E4585),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

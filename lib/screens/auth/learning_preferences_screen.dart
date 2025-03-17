import 'package:flutter/material.dart';
import '../../utils/app_styles.dart';

class LearningPreferencesScreen extends StatefulWidget {
  const LearningPreferencesScreen({super.key});

  @override
  State<LearningPreferencesScreen> createState() =>
      _LearningPreferencesScreenState();
}

class _LearningPreferencesScreenState extends State<LearningPreferencesScreen> {
  final List<String> _selectedReasons = [];
  final List<String> _reasons = [
    'I will study',
    'To prepare for TOEFL exam',
    'Learn language step',
    'Be good',
    'To attend new course',
    'To watch films',
  ];

  int _selectedDuration = 15;
  final List<int> _durations = [15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why do you want to learn English?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reasons.map((reason) {
                  final isSelected = _selectedReasons.contains(reason);
                  return FilterChip(
                    label: Text(reason),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedReasons.add(reason);
                        } else {
                          _selectedReasons.remove(reason);
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppStyles.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppStyles.primaryColor,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? AppStyles.primaryColor : Colors.black87,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              const Text(
                'Choose the duration of lessons per day:',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _durations.map((duration) {
                  final isSelected = duration == _selectedDuration;
                  return ChoiceChip(
                    label: Text('$duration mins'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDuration = duration;
                        });
                      }
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppStyles.primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color:
                          isSelected ? AppStyles.primaryColor : Colors.black87,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // After selecting preferences, go to success screen
                    Navigator.pushNamed(context, '/success');
                  },
                  style: AppStyles.primaryButtonStyle,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

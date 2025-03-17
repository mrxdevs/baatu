import 'package:flutter/material.dart';

class AppStyles {
  static const Color primaryColor = Color(0xFF8E4585);
  static const Color secondaryColor = Color(0xFFF8BBD0);
  static const Color backgroundColor = Color(0xFFF8F8F8);
  
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    elevation: 0,
  );

  static final InputDecoration textFieldDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Colors.grey, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: primaryColor, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  );
}

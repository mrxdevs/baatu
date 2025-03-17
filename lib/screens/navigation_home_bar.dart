import 'package:flutter/material.dart';
import 'package:baatu/screens/sections/words_screen.dart';
import 'package:baatu/screens/sections/videos_screen.dart';
import 'package:baatu/screens/sections/music_screen.dart';
import 'package:baatu/screens/sections/chat_screen.dart';
import 'package:baatu/screens/sections/grammar_screen.dart';
import 'package:baatu/screens/settings_screen.dart';
import 'package:baatu/screens/profile_screen.dart';
import 'package:baatu/screens/news_screen.dart';
import 'package:baatu/screens/chat_connection_screen.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _selectedIndex = 0;

  void _navigateToScreen(BuildContext context, int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = const WordsScreen();
        break;
      case 1:
        screen = const VideosScreen();
        break;
      case 2:
        screen = const MusicScreen();
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
        return;
      case 4:
        screen = const GrammarScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const NewsScreen();
      case 2:
        return const ProfileScreen();
      case 3:
        return const SettingsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ChatConnectionScreen(),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            padding: const EdgeInsets.all(20),
            mainAxisSpacing: 25,
            crossAxisSpacing: 25,
            children: [
              _buildHexagonButton('Words', Icons.abc, 0),
              _buildHexagonButton('Videos', Icons.play_arrow, 1),
              _buildHexagonButton('Music', Icons.music_note, 2),
              _buildHexagonButton('Chat', Icons.chat_bubble, 3),
              _buildHexagonButton('Grammar', Icons.menu_book, 4),
            ],
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildHexagonButton(String label, IconData icon, int index) {
    return GestureDetector(
      onTap: () => _navigateToScreen(context, index),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            margin: const EdgeInsets.all(8),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxWidth),
                  painter: HexagonPainter(
                    borderColor: const Color(0xFF8E4585),
                    borderWidth: 2.0,
                  ),
                ),
                ClipPath(
                  clipper: HexagonClipper(),
                  child: Container(
                    width: constraints.maxWidth,
                    height: constraints.maxWidth,
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToScreen(context, index),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: constraints.maxWidth * 0.25,
                                color: const Color(0xFF8E4585),
                              ),
                              SizedBox(height: constraints.maxWidth * 0.08),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF8E4585),
                                  fontSize: constraints.maxWidth * 0.12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          SafeArea(child: _getCurrentScreen()),
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF8E4585),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(Icons.home_outlined, 0),
                  _buildNavItem(Icons.menu_book_outlined, 1),
                  _buildNavItem(Icons.person_outline, 2),
                  _buildNavItem(Icons.settings_outlined, 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;

  HexagonPainter({required this.borderColor, required this.borderWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    final path = Path();
    final double a = size.width / 2;
    final double b = size.height / 2;

    path.moveTo(size.width, b);
    path.lineTo(size.width * 3 / 4, size.height * 0.067);
    path.lineTo(size.width * 1 / 4, size.height * 0.067);
    path.lineTo(0, b);
    path.lineTo(size.width * 1 / 4, size.height * 0.933);
    path.lineTo(size.width * 3 / 4, size.height * 0.933);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double a = size.width / 2;
    final double b = size.height / 2;

    path.moveTo(size.width, b);
    path.lineTo(size.width * 3 / 4, size.height * 0.067);
    path.lineTo(size.width * 1 / 4, size.height * 0.067);
    path.lineTo(0, b);
    path.lineTo(size.width * 1 / 4, size.height * 0.933);
    path.lineTo(size.width * 3 / 4, size.height * 0.933);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

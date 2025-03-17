import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildProgressIndicator(String label, double percentage, Color color) {
    return Column(
      children: [
        Container(
          width: 65,
          height: 65,
          padding: const EdgeInsets.all(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
              Center(
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${(percentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toLowerCase(),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String title, String content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFFD700),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: Color(0xFF8E4585),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  height: 250,
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
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 3,
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/user.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 40,
                  child: Image.asset(
                    'assets/images/bee.png',
                    width: 80,
                    height: 80,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildProgressIndicator(
                              'words', 0.3, const Color(0xFF8E4585)),
                          const SizedBox(width: 12),
                          _buildProgressIndicator(
                              'videos', 0.1, const Color(0xFFFFD700)),
                          const SizedBox(width: 12),
                          _buildProgressIndicator(
                              'grammar', 0.15, const Color(0xFFFFD700)),
                          const SizedBox(width: 12),
                          _buildProgressIndicator(
                              'chat', 0.25, const Color(0xFFFFD700)),
                          const SizedBox(width: 12),
                          _buildProgressIndicator(
                              'music', 0.5, const Color(0xFF8E4585)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStatItem(
                    Icons.bar_chart,
                    'the level',
                    'intermediate',
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    Icons.add_circle_outline,
                    'Strengths',
                    'Words, Music',
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    Icons.remove_circle_outline,
                    'Weaknesses',
                    'Grammar, Chat, Video',
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    Icons.star,
                    'Total Points',
                    '2,450',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '"Language is the road map of a culture. ',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              TextSpan(
                                text:
                                    'It tells you where its people come from and where they are going."',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '- Rita Mae Brown',
                          style: TextStyle(
                            color: Color(0xFF8E4585),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 180),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

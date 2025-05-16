import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
  static const String routeName = '/news_screen';
}

class _NewsScreenState extends State<NewsScreen> {
  final PageController _pageController = PageController(
    viewportFraction: 0.9,
    initialPage: 0,
  );
  double? _currentPage = 0;
  final List<NewsItem> _newsItems = [
    NewsItem(
      title: "Daily Grammar Tips",
      subtitle: "5 Common Mistakes to Avoid",
      description: "Master these essential grammar rules to improve your English writing and speaking skills. We'll cover common pitfalls and how to avoid them.",
      category: "Grammar",
      timeToRead: "3 min read",
      color: const Color(0xFF8E4585),
      icon: Icons.menu_book_outlined,
    ),
    NewsItem(
      title: "New Music Vocabulary",
      subtitle: "Learn Music Terms in English",
      description: "Expand your musical vocabulary with these essential English terms. Perfect for music lovers and those interested in music theory.",
      category: "Music",
      timeToRead: "4 min read",
      color: const Color(0xFFFFD700),
      icon: Icons.music_note_outlined,
    ),
    NewsItem(
      title: "Conversation Practice",
      subtitle: "Essential Travel Phrases",
      description: "Get ready for your next trip with these must-know travel phrases. Practice real-world conversations and boost your confidence.",
      category: "Speaking",
      timeToRead: "5 min read",
      color: const Color(0xFF8E4585),
      icon: Icons.chat_bubble_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Lessons",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E4585),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Swipe to explore your daily learning content",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _newsItems.length,
                itemBuilder: (context, index) {
                  final double difference = (_currentPage ?? 0) - index;
                  final double scale = 1 - (difference.abs() * 0.1);
                  final double translateY = (difference.abs() * 40);
                  
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..translate(0.0, translateY)
                      ..scale(scale),
                    child: Opacity(
                      opacity: 1 - (difference.abs() * 0.3),
                      child: NewsCard(newsItem: _newsItems[index]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class NewsItem {
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final String timeToRead;
  final Color color;
  final IconData icon;

  const NewsItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.timeToRead,
    required this.color,
    required this.icon,
  });
}

class NewsCard extends StatelessWidget {
  final NewsItem newsItem;

  const NewsCard({
    super.key,
    required this.newsItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: newsItem.color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Center(
              child: Icon(
                newsItem.icon,
                size: 100,
                color: newsItem.color,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: newsItem.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      newsItem.category,
                      style: TextStyle(
                        color: newsItem.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    newsItem.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    newsItem.subtitle,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Text(
                      newsItem.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        newsItem.timeToRead,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: newsItem.color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

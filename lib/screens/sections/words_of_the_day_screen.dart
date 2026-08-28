import 'package:flutter/material.dart';
import '../../model/daily_word_models.dart';
import '../../services/daily_words_service.dart';
import 'word_detail_screen.dart';

class WordsOfTheDayScreen extends StatefulWidget {
  const WordsOfTheDayScreen({super.key});
  static const routeName = '/words_of_the_day';

  @override
  State<WordsOfTheDayScreen> createState() => _WordsOfTheDayScreenState();
}

class _WordsOfTheDayScreenState extends State<WordsOfTheDayScreen>
    with SingleTickerProviderStateMixin {
  final DailyWordsService _service = DailyWordsService();
  bool _isLoading = true;
  DailyWordsResponse? _dailyWords;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  DateTime _selectedDate = DateTime.now();

  static const Color primaryColor = Color(0xFF8E4585);
  static const Color secondaryColor = Color(0xFFF8BBD0);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDailyWords();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<void> _loadDailyWords([DateTime? date]) async {
    if (date != null) {
      _selectedDate = date;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _animationController.reset();
      final dailyWords = await _service.getDailyWords(date: _selectedDate);
      setState(() {
        _dailyWords = dailyWords;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to load daily words: $e';
        _isLoading = false;
      });
    }
  }

  void _previousDay() {
    final prev = _selectedDate.subtract(const Duration(days: 1));
    _loadDailyWords(prev);
  }

  void _nextDay() {
    final next = _selectedDate.add(const Duration(days: 1));
    final now = DateTime.now();
    // Allow up to tomorrow or today
    if (next.isBefore(now.add(const Duration(days: 2)))) {
      _loadDailyWords(next);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF333333),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      _loadDailyWords(picked);
    }
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WordHistoryBottomSheet(
        service: _service,
        onSelectHistoryDate: (selectedDate) {
          Navigator.pop(context);
          _loadDailyWords(selectedDate);
        },
        onSelectWord: (word) {
          Navigator.pop(context);
          _navigateToWordDetail(word);
        },
      ),
    );
  }

  Color _getDifficultyColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFFFF9800);
      case 'advanced':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData _getDifficultyIcon(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Icons.star_border;
      case 'intermediate':
        return Icons.star_half;
      case 'advanced':
        return Icons.star;
      default:
        return Icons.star_border;
    }
  }

  void _navigateToWordDetail(DailyWord word) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordDetailScreen(word: word),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentDayToday = _isToday(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Words of the Day'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Word History',
            onPressed: _showHistoryModal,
          ),
          if (!isCurrentDayToday)
            TextButton.icon(
              onPressed: () => _loadDailyWords(DateTime.now()),
              icon: const Icon(Icons.today, color: Colors.white, size: 18),
              label: const Text('Today', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildDateNavigationBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigationBar() {
    final dateFormatted = _dailyWords?.date ??
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final isTodayDate = _isToday(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: primaryColor, size: 28),
            tooltip: 'Previous Day',
            onPressed: _previousDay,
          ),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    isTodayDate ? 'Today ($dateFormatted)' : dateFormatted,
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20, color: primaryColor),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: primaryColor, size: 28),
            tooltip: 'Next Day',
            onPressed: _nextDay,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading vocabulary...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadDailyWords(_selectedDate),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () => _loadDailyWords(_selectedDate),
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWordOfDayCard(),
              const SizedBox(height: 24),
              _buildSectionTitle(
                _isToday(_selectedDate)
                    ? 'Today\'s Vocabulary'
                    : 'Vocabulary for ${_dailyWords?.date ?? ""}',
              ),
              const SizedBox(height: 16),
              _buildWordsGrid(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordOfDayCard() {
    final word = _dailyWords?.wordOfDay;
    if (word == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _navigateToWordDetail(word),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Word of the Day',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDifficultyBadge(word.difficultyLevel, light: true),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              word.word,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              word.partOfSpeech,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              word.meaning,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.format_quote,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    word.exampleSentence,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tap to learn more',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_dailyWords?.totalWords ?? 0}',
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordsGrid() {
    final words = _dailyWords?.words ?? [];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return _buildWordCard(word, index);
      },
    );
  }

  Widget _buildWordCard(DailyWord word, int index) {
    return GestureDetector(
      onTap: () => _navigateToWordDetail(word),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 250 + (index * 40)),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word.word,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                word.partOfSpeech,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  word.meaning,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildDifficultyBadge(word.difficultyLevel),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: primaryColor.withOpacity(0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String level, {bool light = false}) {
    final color = _getDifficultyColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: light ? Colors.white.withOpacity(0.2) : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDifficultyIcon(level),
            size: 12,
            color: light ? Colors.white : color,
          ),
          const SizedBox(width: 4),
          Text(
            level.isNotEmpty
                ? level.substring(0, 1).toUpperCase() + level.substring(1)
                : 'Word',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: light ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordHistoryBottomSheet extends StatefulWidget {
  final DailyWordsService service;
  final Function(DateTime) onSelectHistoryDate;
  final Function(DailyWord) onSelectWord;

  const _WordHistoryBottomSheet({
    required this.service,
    required this.onSelectHistoryDate,
    required this.onSelectWord,
  });

  @override
  State<_WordHistoryBottomSheet> createState() => _WordHistoryBottomSheetState();
}

class _WordHistoryBottomSheetState extends State<_WordHistoryBottomSheet> {
  bool _loading = true;
  List<WordHistoryItem> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await widget.service.getWordHistory(limit: 30);
      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load history';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: _WordsOfTheDayScreenState.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Word of the Day History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _WordsOfTheDayScreenState.primaryColor,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : _history.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No past words recorded yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _history.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _history[index];
                              DateTime? parsedDate;
                              try {
                                parsedDate = DateTime.parse(item.date);
                              } catch (_) {}

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _WordsOfTheDayScreenState.secondaryColor
                                        .withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: _WordsOfTheDayScreenState.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  item.word.word,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.word.meaning,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.date,
                                      style: TextStyle(
                                        color: _WordsOfTheDayScreenState.primaryColor
                                            .withOpacity(0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  if (parsedDate != null) {
                                    widget.onSelectHistoryDate(parsedDate);
                                  } else {
                                    widget.onSelectWord(item.word);
                                  }
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

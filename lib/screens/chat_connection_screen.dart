import 'package:flutter/material.dart';
import 'call_screen.dart';

class ChatConnectionScreen extends StatefulWidget {
  const ChatConnectionScreen({super.key});

  @override
  State<ChatConnectionScreen> createState() => _ChatConnectionScreenState();
  static const String routeName = '/chat_connection_screen';
}

class _ChatConnectionScreenState extends State<ChatConnectionScreen> {
  bool isTopPick = false;
  String selectedGender = 'Any';

  String _getButtonText() {
    switch (selectedGender.toLowerCase()) {
      case 'any':
        return 'Talk with Anyone';
      case 'female':
        return 'Talk with Female';
      case 'male':
        return 'Talk with Male';
      default:
        return 'Talk with Anyone';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16, top: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: themeColor.withOpacity(0.3), width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Let's connect",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top pick',
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 16,
                        ),
                      ),
                      Switch(
                        value: isTopPick,
                        onChanged: (value) {
                          setState(() {
                            isTopPick = value;
                          });
                        },
                        activeColor: themeColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGenderButton(
                          'Any', selectedGender == 'Any', themeColor),
                      _buildGenderButton(
                          'Female', selectedGender == 'Female', themeColor),
                      _buildGenderButton(
                          'Male', selectedGender == 'Male', themeColor),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CallScreen(
                              callingWith: selectedGender == 'Any'
                                  ? 'Anyone'
                                  : selectedGender,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.phone, color: Colors.white),
                      label: Text(
                        _getButtonText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildUserCard(themeColor),
            const SizedBox(height: 16),
            _buildTopPicksSection(themeColor),
            const SizedBox(height: 16),
            _buildActionButton(
              'Contact us',
              Icons.headset_mic_outlined,
              Icons.toggle_on_outlined,
              themeColor,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Follow us for updates and free coins',
              Icons.group_outlined,
              null,
              themeColor,
            ),
            const SizedBox(height: 12),
            _buildShareButton(themeColor),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderButton(String text, bool isSelected, Color themeColor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: themeColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (text == 'Female') ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.star,
                color: Colors.yellow,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            child: const Icon(
              Icons.person_outline,
              color: Colors.grey,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'vishnu',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                '9 mins',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[100],
            child: Icon(
              Icons.phone_outlined,
              color: themeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPicksSection(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Top picks for Jeet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'New',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    '6',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                6,
                (index) => Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    child: Icon(
                      index == 1
                          ? Icons.person_add_outlined
                          : Icons.person_outline,
                      color: themeColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData leadingIcon,
      IconData? trailingIcon, Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            leadingIcon,
            color: themeColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          if (trailingIcon != null)
            Icon(
              trailingIcon,
              color: themeColor,
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildShareButton(Color themeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.share,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Share with your family and friends',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

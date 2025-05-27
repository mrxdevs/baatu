import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:baatu/services/auth_service.dart';
import 'package:baatu/services/database_service.dart';
import 'package:baatu/utils/app_styles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile_screen';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late DatabaseService _databaseService;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // User profile data
  String _displayName = '';
  String _email = '';
  String _profileImageUrl = '';
  bool _isLoading = true;
  bool _isEditing = false;
  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();

  // User stats
  Map<String, double> _progressStats = {
    'words': 0.3,
    'videos': 0.1,
    'grammar': 0.15,
    'chat': 0.25,
    'music': 0.5,
  };

  String _level = 'intermediate';
  String _strengths = 'Words, Music';
  String _weaknesses = 'Grammar, Chat, Video';
  String _totalPoints = '2,450';

  @override
  void initState() {
    super.initState();
    _databaseService =
        DatabaseService(uid: FirebaseAuth.instance.currentUser?.uid);
    _loadUserData();

    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    print('Loading user data...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user profile data
      if (_authService.user != null) {
        print('Current user ID: ${_authService.user!.uid}');
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(_authService.user!.uid)
            .get();

        print('Document exists: ${userData.exists}');
        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
          print('Retrieved user data: $data');

          setState(() {
            _displayName = data['displayName'] ??
                _authService.user!.email?.split('@')[0] ??
                'User';
            _email = _authService.user!.email ?? '';
            _profileImageUrl = data['profileImageUrl'] ?? '';
            _nameController.text = _displayName;

            print('Display name set to: $_displayName');
            print('Email set to: $_email');
            print('Profile image URL: $_profileImageUrl');

            // Load progress stats if available
            if (data.containsKey('progressStats')) {
              Map<String, dynamic> stats = data['progressStats'];
              print('Progress stats found: $stats');
              stats.forEach((key, value) {
                if (_progressStats.containsKey(key)) {
                  _progressStats[key] = value.toDouble();
                  print('Updated progress stat $key: ${_progressStats[key]}');
                }
              });
            } else {
              print('No progress stats found in user data');
            }

            // Load other stats
            _level = data['level'] ?? _level;
            _strengths = data['strengths'] ?? _strengths;
            _weaknesses = data['weaknesses'] ?? _weaknesses;
            _totalPoints = data['totalPoints']?.toString() ?? _totalPoints;

            print('Level: $_level');
            print('Strengths: $_strengths');
            print('Weaknesses: $_weaknesses');
            print('Total Points: $_totalPoints');
          });
        } else {
          print('No user document found');
        }
      } else {
        print('No authenticated user found');
      }
    } catch (e, stackTrace) {
      print('Error loading user data: $e');
      print('Stack trace: $stackTrace');
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('Finished loading user data. Loading state: $_isLoading');
    }
  }

  Future<void> _updateUserData() async {
    if (_authService.user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare data to update
      Map<String, dynamic> userData = {
        'displayName': _nameController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Upload image if selected
      if (_imageFile != null) {
        String imageUrl = await _uploadProfileImage();
        userData['profileImageUrl'] = imageUrl;
        _profileImageUrl = imageUrl;
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_authService.user!.uid)
          .update(userData);

      setState(() {
        _displayName = _nameController.text.trim();
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _uploadProfileImage() async {
    if (_imageFile == null || _authService.user == null) return '';

    try {
      // Create storage reference
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_authService.user!.uid}.jpg');

      // Upload file
      await storageRef.putFile(_imageFile!);

      // Get download URL
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Widget _buildProgressIndicator(String label, double percentage, Color color) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animation),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              padding: const EdgeInsets.all(4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: percentage),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeWidth: 6,
                      );
                    },
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
                        child: TweenAnimationBuilder<int>(
                          tween: IntTween(
                              begin: 0, end: (percentage * 100).toInt()),
                          duration: const Duration(milliseconds: 1500),
                          builder: (context, value, child) {
                            return Text(
                              '$value%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            );
                          },
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
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String title, String content) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(_animation),
        child: Container(
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
                        color: AppStyles.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 150,
            height: 20,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 14,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? Center(child: _buildLoadingShimmer())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: AppStyles.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _isEditing ? _pickImage : null,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFFFD700),
                                            width: 3,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: _imageFile != null
                                              ? Image.file(
                                                  _imageFile!,
                                                  fit: BoxFit.cover,
                                                )
                                              : _profileImageUrl.isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl:
                                                          _profileImageUrl,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context,
                                                              url) =>
                                                          const CircularProgressIndicator(),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          Image.asset(
                                                        'assets/images/user.png',
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Image.asset(
                                                      'assets/images/user.png',
                                                      fit: BoxFit.cover,
                                                    ),
                                        ),
                                      ),
                                      if (_isEditing)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppStyles.primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _isEditing
                                    ? Container(
                                        width: 200,
                                        child: TextField(
                                          controller: _nameController,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppStyles.primaryColor,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Enter your name',
                                            border: UnderlineInputBorder(),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: AppStyles.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _displayName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppStyles.primaryColor,
                                        ),
                                      ),
                                Text(
                                  _email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
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
                        Positioned(
                          top: 50,
                          right: 20,
                          child: _isEditing
                              ? Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check),
                                      color: Colors.green,
                                      onPressed: _updateUserData,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      color: Colors.red,
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = false;
                                          _nameController.text = _displayName;
                                          _imageFile = null;
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: AppStyles.primaryColor,
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  },
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding:
                                      EdgeInsets.only(left: 12, bottom: 12),
                                  child: Text(
                                    'Your Progress',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppStyles.primaryColor,
                                    ),
                                  ),
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildProgressIndicator(
                                          'words',
                                          _progressStats['words']!,
                                          AppStyles.primaryColor),
                                      const SizedBox(width: 12),
                                      _buildProgressIndicator(
                                          'videos',
                                          _progressStats['videos']!,
                                          const Color(0xFFFFD700)),
                                      const SizedBox(width: 12),
                                      _buildProgressIndicator(
                                          'grammar',
                                          _progressStats['grammar']!,
                                          const Color(0xFFFFD700)),
                                      const SizedBox(width: 12),
                                      _buildProgressIndicator(
                                          'chat',
                                          _progressStats['chat']!,
                                          const Color(0xFFFFD700)),
                                      const SizedBox(width: 12),
                                      _buildProgressIndicator(
                                          'music',
                                          _progressStats['music']!,
                                          AppStyles.primaryColor),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildStatItem(
                            Icons.bar_chart,
                            'the level',
                            _level,
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            Icons.add_circle_outline,
                            'Strengths',
                            _strengths,
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            Icons.remove_circle_outline,
                            'Weaknesses',
                            _weaknesses,
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            Icons.star,
                            'Total Points',
                            _totalPoints,
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
                                    color: AppStyles.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

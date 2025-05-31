import 'package:flutter/material.dart';
import 'package:baatu/model/user_details.dart';
import 'package:baatu/utils/app_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../methods/print_helper.dart';

class EditProfileScreen extends StatefulWidget {
  static const String routeName = '/edit_profile_screen';
  final UserDetails userDetails;

  const EditProfileScreen({super.key, required this.userDetails});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late UserDetails _userDetails;
  File? _imageFile;
  bool _isLoading = false;

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();

  // Gender selection
  String? _selectedGender;
  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  // Interests
  final List<String> _availableInterests = [
    'Reading',
    'Writing',
    'Music',
    'Movies',
    'Travel',
    'Sports',
    'Cooking',
    'Photography',
    'Art',
    'Technology',
    'Science',
    'History',
    'Languages',
    'Gaming',
    'Fitness',
    'Fashion',
    'Food',
    'Nature'
  ];
  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _userDetails = widget.userDetails;
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController.text = _userDetails.name ?? '';
    _bioController.text = _userDetails.bio ?? '';
    _locationController.text = _userDetails.location ?? '';
    _websiteController.text = _userDetails.website ?? '';
    _phoneController.text = _userDetails.phoneNumber ?? '';
    _dobController.text = _userDetails.dob ?? '';
    _professionController.text = _userDetails.profession ?? '';
    _educationController.text = _userDetails.education ?? '';
    _selectedGender = _userDetails.gender;
    _selectedInterests = _userDetails.interests ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _professionController.dispose();
    _educationController.dispose();
    super.dispose();
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
      printmsg('Failed to pick image: $e');
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_imageFile == null || _userDetails.uid == null) return null;

    try {
      // Create storage reference
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_userDetails.uid}.jpg');

      // Upload file
      await storageRef.putFile(_imageFile!);

      // Get download URL
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      printmsg('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppStyles.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare data to update
      Map<String, dynamic> userData = {
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'gender': _selectedGender,
        'dob': _dobController.text.trim(),
        'profession': _professionController.text.trim(),
        'education': _educationController.text.trim(),
        'interests': _selectedInterests,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Upload image if selected
      if (_imageFile != null) {
        String? imageUrl = await _uploadProfileImage();
        if (imageUrl != null) {
          userData['profileImageUrl'] = imageUrl;
          _userDetails.profileImage = imageUrl;
        }
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userDetails.uid)
          .update(userData);

      // Update user details object
      _userDetails.name = _nameController.text.trim();
      _userDetails.bio = _bioController.text.trim();
      _userDetails.location = _locationController.text.trim();
      _userDetails.website = _websiteController.text.trim();
      _userDetails.phoneNumber = _phoneController.text.trim();
      _userDetails.gender = _selectedGender;
      _userDetails.dob = _dobController.text.trim();
      _userDetails.profession = _professionController.text.trim();
      _userDetails.education = _educationController.text.trim();
      _userDetails.interests = _selectedInterests;

      // Update display name in Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.updateDisplayName(_nameController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      // Return to previous screen with updated user details
      Navigator.pop(context, _userDetails);
    } catch (e) {
      printmsg('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
    IconData? icon,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        decoration: AppStyles.textFieldDecoration.copyWith(
          labelText: label,
          hintText: hint,
          prefixIcon:
              icon != null ? Icon(icon, color: AppStyles.primaryColor) : null,
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    // Ensure _selectedGender is in _genderOptions or set to null
    if (_selectedGender != null && !_genderOptions.contains(_selectedGender)) {
      _selectedGender = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: AppStyles.textFieldDecoration.copyWith(
          labelText: 'Gender',
          prefixIcon:
              const Icon(Icons.person_outline, color: AppStyles.primaryColor),
        ),
        value: _selectedGender,
        hint: const Text('Select gender'),
        items: _genderOptions.map((String gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue;
          });
        },
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Interests',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              selectedColor: AppStyles.secondaryColor,
              checkmarkColor: AppStyles.primaryColor,
              backgroundColor: Colors.grey[200],
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedInterests.add(interest);
                  } else {
                    _selectedInterests.remove(interest);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppStyles.primaryColor,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _imageFile != null
                                    ? Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                      )
                                    : _userDetails.profileImage != null &&
                                            _userDetails
                                                .profileImage!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl:
                                                _userDetails.profileImage!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const CircularProgressIndicator(),
                                            errorWidget:
                                                (context, url, error) =>
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
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name',
                      hint: 'Enter your full name',
                      icon: Icons.person,
                      isRequired: true,
                    ),
                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      hint: 'Tell us about yourself',
                      icon: Icons.info_outline,
                      maxLines: 3,
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      controller: _dobController,
                      label: 'Date of Birth',
                      hint: 'DD/MM/YYYY',
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                    ),
                    _buildGenderDropdown(),
                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      hint: 'City, Country',
                      icon: Icons.location_on_outlined,
                    ),
                    _buildTextField(
                      controller: _websiteController,
                      label: 'Website',
                      hint: 'https://example.com',
                      icon: Icons.link,
                      keyboardType: TextInputType.url,
                    ),
                    _buildTextField(
                      controller: _professionController,
                      label: 'Profession',
                      hint: 'Your current job',
                      icon: Icons.work_outline,
                    ),
                    _buildTextField(
                      controller: _educationController,
                      label: 'Education',
                      hint: 'Your highest education',
                      icon: Icons.school_outlined,
                    ),
                    _buildInterestsSection(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: AppStyles.primaryButtonStyle,
                        child: const Text('Save Profile'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

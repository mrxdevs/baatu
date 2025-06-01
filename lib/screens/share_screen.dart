import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  static const String routeName = '/share_screen';

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  List<Contact> _contacts = [];
  bool _isLoading = false;
  final String _inviteMessage =
      "Join me on Baatu! It's an amazing app for learning and practicing English. Download now: https://baatu.app";
  Map<String, bool> _registeredUsers = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        final contacts = await ContactsService.getContacts();
        setState(() {
          _contacts = contacts.toList();
        });
        // Check registration status for all contacts
        _checkRegistrationStatus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading contacts: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkRegistrationStatus() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    for (var contact in _contacts) {
      final phone =
          contact.phones?.firstOrNull?.value?.replaceAll(RegExp(r'[^\d+]'), '');
      if (phone != null && phone.isNotEmpty) {
        try {
          final querySnapshot = await firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: phone)
              .get();

          setState(() {
            _registeredUsers[phone] = querySnapshot.docs.isNotEmpty;
          });
        } catch (e) {
          print('Error checking registration for $phone: $e');
        }
      }
    }
  }

  Future<void> _shareViaWhatsApp(String phoneNumber) async {
    final url =
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(_inviteMessage)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed')),
        );
      }
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final url = 'sms:$phoneNumber?body=${Uri.encodeComponent(_inviteMessage)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _shareGeneralInvite() {
    Share.share(_inviteMessage);
  }

  Widget _buildContactStatus(String phone) {
    final isRegistered = _registeredUsers[phone] ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRegistered
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRegistered ? Icons.check_circle : Icons.person_add_outlined,
            color: isRegistered ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isRegistered ? 'Registered' : 'Invite',
            style: TextStyle(
              color: isRegistered ? Colors.green : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Friends'),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareGeneralInvite,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: themeColor.withOpacity(0.1),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Share Baatu with your contacts and help them improve their English!',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      final phone = contact.phones?.firstOrNull?.value
                              ?.replaceAll(RegExp(r'[^\d+]'), '') ??
                          '';

                      if (phone.isEmpty) return const SizedBox.shrink();

                      final isRegistered = _registeredUsers[phone] ?? false;

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                              contact.displayName?[0].toUpperCase() ?? '?'),
                        ),
                        title: Text(contact.displayName ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(phone),
                            const SizedBox(height: 4),
                            _buildContactStatus(phone),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isRegistered) ...[
                              IconButton(
                                icon: const Icon(Icons.message),
                                onPressed: () => _sendSMS(phone),
                              ),
                              IconButton(
                                icon: const Icon(Icons
                                    .send), // Changed to send icon instead of whatsapp
                                onPressed: () => _shareViaWhatsApp(phone),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

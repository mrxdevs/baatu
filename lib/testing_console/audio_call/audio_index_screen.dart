import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:developer';
import 'audio_call_screen.dart';

class AudioIndexScreen extends StatefulWidget {
  const AudioIndexScreen({super.key});

  static const String routeName = '/audio_index_screen';

  @override
  State<AudioIndexScreen> createState() => _AudioIndexScreenState();
}

class _AudioIndexScreenState extends State<AudioIndexScreen> {
  final _channelController = TextEditingController();
  bool _validateError = false;
  ClientRoleType? _role = ClientRoleType.clientRoleBroadcaster;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Call'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 40),
              Icon(
                Icons.call,
                size: 100,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _channelController,
                decoration: InputDecoration(
                  errorText:
                      _validateError ? 'Channel name is mandatory' : null,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(width: 1),
                  ),
                  hintText: 'Channel name',
                  prefixIcon: Icon(Icons.group, color: theme.primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose your role:',
                style: theme.textTheme.titleMedium,
              ),
              RadioListTile<ClientRoleType>(
                title: const Text('Broadcaster (Speaker)'),
                subtitle: const Text('You can speak in the call'),
                value: ClientRoleType.clientRoleBroadcaster,
                groupValue: _role,
                activeColor: theme.primaryColor,
                onChanged: (ClientRoleType? value) {
                  setState(() {
                    _role = value;
                  });
                },
              ),
              RadioListTile<ClientRoleType>(
                title: const Text('Audience (Listener)'),
                subtitle: const Text('You can only listen to the call'),
                value: ClientRoleType.clientRoleAudience,
                groupValue: _role,
                activeColor: theme.primaryColor,
                onChanged: (ClientRoleType? value) {
                  setState(() {
                    _role = value;
                  });
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onJoin() async {
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });

    if (_channelController.text.isNotEmpty) {
      // Request microphone permission
      await _handlePermission(Permission.microphone);

      // Navigate to call screen
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioCallScreen(
            channelName: _channelController.text,
            role: _role!,
          ),
        ),
      );
    }
  }

  // Permission handler method
  Future<void> _handlePermission(Permission permission) async {
    final status = await permission.request();
    log('$permission status: $status');

    if (status != PermissionStatus.granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for audio calls'),
        ),
      );
    }
  }
}

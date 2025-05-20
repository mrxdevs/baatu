import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:developer';
import './video_call_screen.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 40),
              Image.network('https://tinyurl.com/2p889y4k'),
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
                ),
              ),
              RadioListTile(
                title: const Text('Broadcaster'),
                value: ClientRoleType.clientRoleBroadcaster,
                groupValue: _role,
                onChanged: (ClientRoleType? value) {
                  setState(() {
                    _role = value;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Audience'),
                value: ClientRoleType.clientRoleAudience,
                groupValue: _role,
                onChanged: (ClientRoleType? value) {
                  setState(() {
                    _role = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _onJoin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Join'),
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
      // Handle permissions
      await _handlePermission(Permission.camera);
      await _handlePermission(Permission.microphone);

      // Navigate to call screen
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            channelName: _channelController.text,
            role: _role!,
          ),
        ),
      );
    }
  }

  // Permission method
  Future<void> _handlePermission(Permission permission) async {
    final status = await permission.request();
    log('$permission status: $status');
  }
}

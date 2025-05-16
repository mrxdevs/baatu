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
        title: Text('Index Page'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: <Widget>[
              SizedBox(height: 40),
              Image.network('https://tinyurl.com/2p889y4k'),
              const SizedBox(height: 40),
              TextField(
                controller: _channelController,
                decoration: InputDecoration(
                  errorText:
                      _validateError ? 'Channel name is mandatory' : null,
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(width: 1),
                  ),
                  hintText: 'Channel name',
                ),
              ),
              RadioListTile(
                  title: Text('Broadcaster'),
                  value: ClientRoleType.clientRoleBroadcaster,
                  groupValue: _role,
                  onChanged: (ClientRoleType? value) {
                    _role = value;
                    setState(() {});
                  }),
              RadioListTile(
                  title: Text('Audience'),
                  value: ClientRoleType.clientRoleAudience,
                  groupValue: _role,
                  onChanged: (ClientRoleType? value) {
                    _role = value;
                    setState(() {});
                  }),
              ElevatedButton(onPressed: _onJoin, child: Text('Join'))
            ])),
      ),
    );
  }

  Future<void> _onJoin() async {
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });

    //hadle permission
    if (_channelController.text.isNotEmpty) {
      await _handlePermission(Permission.camera).then((value) async {
        await _handlePermission(Permission.microphone);
      });

      await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              chennelName: _channelController.text,
              role: _role!,
            ),
          ));
    }
  }

  //Pemission method
  Future<void> _handlePermission(Permission permission) async {
    final result = permission.request();
    log('$permission is ${result}');
  }
}

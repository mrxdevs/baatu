import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:flutter/material.dart';

class VideoCallScreen extends StatefulWidget {
  final String? chennelName;
  final ClientRoleType? role;
  const VideoCallScreen({super.key, this.chennelName, this.role});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
  static const String routeName = '/video_call_screen';
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Call Screen'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Text('Video Call Screen'),
      ),
    );
  }
}

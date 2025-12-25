import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';

import '../video_call/call_setting.dart';

class AudioCallScreen extends StatefulWidget {
  final String channelName;
  final ClientRoleType role;

  const AudioCallScreen({
    super.key,
    required this.channelName,
    required this.role,
  });

  static const String routeName = '/audio_call_screen';

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final _infoStrings = <String>[];
  bool _muted = false;
  late final RtcEngine _engine;
  final List<int> _users = <int>[];
  bool _joined = false;
  bool _speaking = false;
  int _speakingUserId = -1;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  Future<void> initialize() async {
    if (appId.isEmpty) {
      setState(() {
        _infoStrings.add('APP_ID is missing, please provide your APP_ID');
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

    // Create RTC Engine instance
    _engine = createAgoraRtcEngine();
    await initAgoraRtcEngine();
    addAgoraEventHandlers();

    // Join the channel
    await _engine.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: widget.role,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
  }

  Future<void> initAgoraRtcEngine() async {
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // Enable audio
    await _engine.enableAudio();
    await _engine
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: widget.role);

    // Set audio parameters for better quality
    await _engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
  }

  void addAgoraEventHandlers() {
    _engine.registerEventHandler(RtcEngineEventHandler(
      onError: (ErrorCodeType err, String msg) {
        setState(() {
          final info = 'Error: $err, $msg';
          _infoStrings.add(info);
        });
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        setState(() {
          final info = 'Join channel: ${connection.channelId}';
          _infoStrings.add(info);
          _joined = true;
        });
      },
      onLeaveChannel: (connection, stats) {
        setState(() {
          _infoStrings.add('Leave channel');
          _users.clear();
          _joined = false;
        });
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        setState(() {
          final info = 'User joined: $remoteUid';
          _infoStrings.add(info);
          _users.add(remoteUid);
        });
      },
      onUserOffline: (connection, remoteUid, reason) {
        setState(() {
          final info = 'User offline: $remoteUid';
          _infoStrings.add(info);
          _users.remove(remoteUid);

          if (_speakingUserId == remoteUid) {
            _speaking = false;
            _speakingUserId = -1;
          }
        });
      },
      onActiveSpeaker: (rtc, uid) {
        setState(() {
          _speaking = true;
          _speakingUserId = uid;
        });
      },
      onAudioVolumeIndication: (connection, speakers, _red, totalVolume) {
        // Update UI based on who is speaking
        for (var speaker in speakers) {
          if (speaker.volume != null &&
              speaker.volume! > 50 &&
              speaker.uid != null) {
            // Threshold for considering someone is speaking
            setState(() {
              _speaking = true;
              _speakingUserId = speaker.uid ?? 0;
            });
            break;
          } else {
            setState(() {
              _speaking = false;
              _speakingUserId = -1;
            });
          }
        }
      },
    ));
  }

  // Helper function to get user avatar
  Widget _getUserAvatar(int uid,
      {bool isSpeaking = false, bool isLocal = false}) {
    final theme = Theme.of(context);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isSpeaking
            ? theme.primaryColor
            : theme.primaryColor.withOpacity(0.5),
        shape: BoxShape.circle,
        border: isSpeaking
            ? Border.all(color: theme.colorScheme.secondary, width: 3)
            : null,
      ),
      child: Center(
        child: Text(
          isLocal ? 'You' : 'User $uid',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: isSpeaking ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // UI for participants
  Widget _participantsView() {
    final List<Widget> participants = [];

    // Add local user if broadcaster
    if (widget.role == ClientRoleType.clientRoleBroadcaster) {
      participants.add(
        Column(
          children: [
            _getUserAvatar(0,
                isSpeaking: _speaking && _speakingUserId == 0, isLocal: true),
            const SizedBox(height: 8),
            const Text('You (Speaker)'),
            if (_speaking && _speakingUserId == 0)
              const Icon(Icons.mic, color: Colors.green),
          ],
        ),
      );
    }

    // Add remote users
    for (var uid in _users) {
      participants.add(
        Column(
          children: [
            _getUserAvatar(uid,
                isSpeaking: _speaking && _speakingUserId == uid),
            const SizedBox(height: 8),
            Text('User $uid'),
            if (_speaking && _speakingUserId == uid)
              const Icon(Icons.mic, color: Colors.green),
          ],
        ),
      );
    }

    if (participants.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for other participants to join',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 20,
      children: participants,
    );
  }

  // Info panel to show events
  Widget _panel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            reverse: true,
            itemCount: _infoStrings.length,
            itemBuilder: (BuildContext context, int index) {
              if (_infoStrings.isEmpty) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _infoStrings[index],
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Toolbar with controls
  Widget _toolbar() {
    final theme = Theme.of(context);

    // Disable the mic button if user is audience
    final bool isBroadcaster =
        widget.role == ClientRoleType.clientRoleBroadcaster;

    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Mute Button
          RawMaterialButton(
            onPressed: isBroadcaster ? _onToggleMute : null,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: isBroadcaster
                ? (_muted ? Colors.redAccent : theme.primaryColor)
                : Colors.grey,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              _muted ? Icons.mic_off : Icons.mic,
              color: Colors.white,
              size: 24.0,
            ),
          ),
          const SizedBox(width: 20),
          // End Call Button
          RawMaterialButton(
            onPressed: _onCallEnd,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 30.0,
            ),
          ),
          const SizedBox(width: 20),
          // Speaker Button
          RawMaterialButton(
            onPressed: _onSwitchSpeaker,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: theme.primaryColor,
            padding: const EdgeInsets.all(12.0),
            child: const Icon(
              Icons.volume_up,
              color: Colors.white,
              size: 24.0,
            ),
          ),
        ],
      ),
    );
  }

  // Button actions
  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _engine.muteLocalAudioStream(_muted);
  }

  void _onCallEnd() {
    Navigator.pop(context);
  }

  void _onSwitchSpeaker() {
    _engine.setEnableSpeakerphone(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Speaker turned on'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Call: ${widget.channelName}'),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Stack(
          children: <Widget>[
            // Participants
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Audio Call in Progress',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Channel: ${widget.channelName}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Role: ${widget.role == ClientRoleType.clientRoleBroadcaster ? "Broadcaster" : "Audience"}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: _participantsView(),
                  ),
                ],
              ),
            ),
            // Toolbar
            _toolbar(),
          ],
        ),
      ),
    );
  }
}

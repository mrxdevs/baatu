import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'call_setting.dart';

class VideoCallScreen extends StatefulWidget {
  final String? channelName;  // Fixed typo in variable name
  final ClientRoleType? role;
  const VideoCallScreen({super.key, this.channelName, this.role});  // Fixed typo

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
  static const String routeName = '/video_call_screen';
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  bool viewPanel = false;
  late RtcEngine _engine;  // Removed nullable to ensure initialization

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
        _infoStrings.add('APP_ID missing, please provide your APP_ID in settings.dart');
        _infoStrings.add('Joining a channel: ${widget.channelName}');
      });
      return;
    }

    // Create RtcEngine instance
    _engine = createAgoraRtcEngine();
    await initAgoraRtcEngine();
    addAgoraEventHandlers();
  }

  Future<void> initAgoraRtcEngine() async {
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: widget.role!);
    await _engine.startPreview();

    VideoEncoderConfiguration configuration = VideoEncoderConfiguration(
      dimensions: VideoDimensions(width: 1920, height: 1080),
    );
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(
      token: token,
      channelId: widget.channelName!,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: widget.role!,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
  }

  void addAgoraEventHandlers() {
    _engine.registerEventHandler(RtcEngineEventHandler(
      onError: (ErrorCodeType err, String msg) {
        setState(() {
          final info = 'onError: $err, $msg';
          _infoStrings.add(info);
        });
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        setState(() {  // Added setState to update UI
          final info = 'onJoinChannel: ${connection.channelId}, elapsed: $elapsed';
          _infoStrings.add(info);
        });
      },
      onLeaveChannel: (connection, stats) {
        setState(() {
          _infoStrings.add('onLeaveChannel');
          _users.clear();
        });
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        setState(() {
          final info = 'userJoined: $remoteUid';
          _infoStrings.add(info);
          _users.add(remoteUid);
        });
      },
      onUserOffline: (connection, remoteUid, reason) {
        setState(() {
          final info = 'userOffline: $remoteUid';
          _infoStrings.add(info);
          _users.remove(remoteUid);
        });
      },
      onFirstRemoteVideoFrame: (rtc, uid, width, height, elapsed) {
        setState(() {
          final info = 'firstRemoteVideo: $uid ${width}x $height Connection Channel: ${rtc.channelId} Elapsed: $elapsed connection LocalUid: ${rtc.localUid}';
          _infoStrings.add(info);
        });
      },
    ));
  }

  Widget _viewRows() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRoleType.clientRoleBroadcaster) {
      // Local preview
      list.add(AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      ));
    }
    
    // Remote videos
    for (var uid in _users) {
      list.add(AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: widget.channelName!),
        ),
      ));
    }
    
    final views = list;
    
    if (views.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for other participants to join',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Column(
      children: List.generate(
        views.length,
        (index) => Expanded(child: views[index]),
      ),
    );
  }

  // Display remote user's video
  Widget _remoteVideo(
    int? uid,
    String? channel,
    RtcEngine engine,
  ) {
    if (uid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: channel),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }

  _toolBar() {
    if (widget.role == ClientRoleType.clientRoleBroadcaster) {
      return Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RawMaterialButton(
                  onPressed: () {
                    setState(() {
                      muted = !muted;
                    });
                    _engine?.muteLocalAudioStream(muted);
                  },
                  shape: CircleBorder(),
                  elevation: 2,
                  fillColor: muted ? Colors.redAccent : Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: muted ? Colors.redAccent : Colors.blueAccent,
                    size: 20,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  shape: CircleBorder(),
                  elevation: 2,
                  fillColor: Colors.redAccent,
                  padding: const EdgeInsets.all(15),
                  child: Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    setState(() {
                      muted = !muted;
                    });
                    _engine?.muteLocalAudioStream(muted);
                  },
                  shape: CircleBorder(),
                  elevation: 2,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.switch_camera_outlined,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                )
              ]));
    } else {
      return const SizedBox(); // Add your logic for audience's toolbar here
    }
  }

  Widget _panel() {
    return Visibility(
      visible: viewPanel,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: ListView.builder(
              reverse: true,
              itemCount: _infoStrings.length,
              itemBuilder: (BuildContext context, int index) {
                if (_infoStrings.isEmpty) {
                  return const Text(
                    'No info',
                    textAlign: TextAlign.center,
                  );
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Call Screen'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                viewPanel = !viewPanel;
              });
            },
            icon: Icon(viewPanel ? Icons.visibility_off : Icons.visibility),
          ),
        ],
      ),
      body: Center(
        child: Stack(
          children: <Widget>[
            _viewRows(),
            _panel(),
            _toolBar(),
          ],
        ),
      ),
    );
  }
}

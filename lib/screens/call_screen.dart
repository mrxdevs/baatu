import 'package:flutter/material.dart';
import 'dart:async';

class CallScreen extends StatefulWidget {
  final String callingWith;

  const CallScreen({
    super.key,
    required this.callingWith,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool isMuted = false;
  bool isSpeakerOn = false;
  bool isConnected = false;
  Duration duration = Duration.zero;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Simulate connection after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isConnected = true;
        });
        startTimer();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        duration = Duration(seconds: timer.tick);
      });
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours =
        duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : '';
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isConnected
                        ? widget.callingWith
                        : 'Calling ${widget.callingWith}...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isConnected ? formatDuration(duration) : 'Connecting...',
                    style: TextStyle(
                      color: isConnected ? themeColor : Colors.white70,
                      fontSize: 18,
                      fontWeight:
                          isConnected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(
                    icon: isMuted ? Icons.mic_off : Icons.mic,
                    color: isMuted ? Colors.red : Colors.white,
                    onTap: () {
                      setState(() {
                        isMuted = !isMuted;
                      });
                    },
                  ),
                  _buildCallButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    backgroundColor: Colors.red.shade100,
                    onTap: () {
                      timer?.cancel();
                      Navigator.of(context).pop();
                    },
                    size: 72,
                  ),
                  _buildCallButton(
                    icon: isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    color: isSpeakerOn ? themeColor : Colors.white,
                    onTap: () {
                      setState(() {
                        isSpeakerOn = !isSpeakerOn;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    required VoidCallback onTap,
    double size = 64,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.white.withOpacity(0.1),
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }
}

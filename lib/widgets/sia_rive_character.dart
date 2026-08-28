import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Rive-based animated character for Sia (alternative to CustomPainter).
///
/// Uses the anime-girl community asset. The Rive state machine is probed
/// at load time — if inputs like 'isTalking', 'isListening', etc. exist
/// they are wired up; otherwise the default animation plays.
class SiaRiveCharacter extends StatefulWidget {
  final bool isSpeaking;
  final bool isListening;
  final bool isThinking;
  final int currentWordIndex;

  const SiaRiveCharacter({
    super.key,
    this.isSpeaking = false,
    this.isListening = false,
    this.isThinking = false,
    this.currentWordIndex = 0,
  });

  @override
  State<SiaRiveCharacter> createState() => _SiaRiveCharacterState();
}

class _SiaRiveCharacterState extends State<SiaRiveCharacter> {
  Artboard? _artboard;
  StateMachineController? _controller;

  // Inputs that may or may not exist on the state machine
  SMIBool? _isTalking;
  SMIBool? _isListening;
  SMINumber? _mouthOpen;

  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    try {
      final data = await RiveFile.asset('assets/rive/sia_anime_girl.riv');

      final artboard = data.mainArtboard.instance();

      // Try to find and attach a state machine controller
      StateMachineController? ctrl;
      for (final animation in artboard.animations) {
        if (animation is StateMachine) {
          ctrl = StateMachineController.fromArtboard(artboard, animation.name);
          if (ctrl != null) {
            artboard.addController(ctrl);
            break;
          }
        }
      }

      // If no state machine found, just use a simple animation controller
      if (ctrl == null) {
        // Fallback: use SimpleAnimation for the first animation
        final simpleCtrl = SimpleAnimation(
          artboard.animations.isNotEmpty ? artboard.animations.first.name : 'idle',
        );
        artboard.addController(simpleCtrl);
      }

      // Probe for known input names
      if (ctrl != null) {
        for (final input in ctrl.inputs) {
          final name = input.name.toLowerCase();
          if (name.contains('talk') || name.contains('speak')) {
            if (input is SMIBool) _isTalking = input;
          }
          if (name.contains('listen')) {
            if (input is SMIBool) _isListening = input;
          }
          if (name.contains('mouth')) {
            if (input is SMINumber) _mouthOpen = input;
          }
        }
      }

      if (mounted) {
        setState(() {
          _artboard = artboard;
          _controller = ctrl;
          _loaded = true;
        });
      }
    } catch (e) {
      debugPrint('SiaRiveCharacter: Error loading .riv file: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant SiaRiveCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Wire speaking/listening state to Rive inputs if they exist
    _isTalking?.value = widget.isSpeaking;
    _isListening?.value = widget.isListening;

    // Lip-sync: vary mouth openness on word changes
    if (widget.currentWordIndex != oldWidget.currentWordIndex &&
        widget.isSpeaking &&
        _mouthOpen != null) {
      _mouthOpen!.value = 50 + (widget.currentWordIndex % 3) * 20.0; // vary 50-90
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _mouthOpen?.value = 10;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          'Rive asset error',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
        ),
      );
    }

    if (!_loaded || _artboard == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
          strokeWidth: 2,
        ),
      );
    }

    return Rive(
      artboard: _artboard!,
      fit: BoxFit.contain,
      alignment: Alignment.center,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/socket_service.dart';
import '../../utils/app_colors.dart';

class CallScreen extends StatefulWidget {
  final String callerId;
  final String callerName;
  final String receiverId;
  final bool isVideo;
  final bool isIncoming;
  final Map<String, dynamic>? incomingSignal;

  const CallScreen({
    Key? key,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.isVideo,
    this.isIncoming = false,
    this.incomingSignal,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final SocketService _socketService = SocketService();
  
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isCallAnswered = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _setupSocketListeners();
    
    if (widget.isIncoming) {
      // Just wait for user to answer
    } else {
      // Initiate call
      _startCall();
    }
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _setupSocketListeners() {
    _socketService.onCallAnswered((data) async {
      if (!mounted) return;
      setState(() => _isCallAnswered = true);
      
      final signal = data['signal'];
      final sessionDescription = RTCSessionDescription(
        signal['sdp'],
        signal['type'],
      );
      await _peerConnection?.setRemoteDescription(sessionDescription);
    });

    _socketService.onIceCandidate((data) async {
      final candidateMap = data['candidate'];
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
    });

    _socketService.onCallEnded((data) {
      if (mounted) _endCallLocally();
    });

    _socketService.onCallRejected((data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call declined')),
        );
        _endCallLocally();
      }
    });
  }

  Future<void> _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      final targetId = widget.isIncoming ? widget.callerId : widget.receiverId;
      _socketService.sendIceCandidate(targetId, {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      if (!mounted) return;
      setState(() {
        _remoteStream = stream;
        _remoteRenderer.srcObject = stream;
      });
    };
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': widget.isVideo ? {'facingMode': 'user'} : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    
    if (widget.isVideo) {
      _localRenderer.srcObject = _localStream;
    }
    
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  Future<void> _startCall() async {
    await _createPeerConnection();
    await _getUserMedia();

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _socketService.callUser(
      widget.receiverId,
      {
        'sdp': offer.sdp,
        'type': offer.type,
      },
      widget.callerName,
      widget.isVideo,
    );
  }

  Future<void> _answerCall() async {
    await _createPeerConnection();
    await _getUserMedia();

    final signal = widget.incomingSignal!;
    final sessionDescription = RTCSessionDescription(
      signal['sdp'],
      signal['type'],
    );
    await _peerConnection!.setRemoteDescription(sessionDescription);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _socketService.answerCall(widget.callerId, {
      'sdp': answer.sdp,
      'type': answer.type,
    });

    setState(() => _isCallAnswered = true);
  }

  void _rejectCall() {
    _socketService.rejectCall(widget.callerId);
    Navigator.of(context).pop();
  }

  void _endCall() {
    final targetId = widget.isIncoming ? widget.callerId : widget.receiverId;
    _socketService.endCall(targetId);
    _endCallLocally();
  }

  void _endCallLocally() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.getTracks().forEach((track) => track.stop());
    _peerConnection?.close();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _toggleMute() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks()[0];
      setState(() {
        _isMuted = !_isMuted;
        audioTrack.enabled = !_isMuted;
      });
    }
  }

  void _toggleVideo() {
    if (_localStream != null && widget.isVideo) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      setState(() {
        _isVideoOff = !_isVideoOff;
        videoTrack.enabled = !_isVideoOff;
      });
    }
  }

  @override
  void dispose() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.getTracks().forEach((track) => track.stop());
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video or Placeholder
            if (widget.isVideo && _isCallAnswered)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : '?',
                          style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.callerName,
                      style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isCallAnswered
                          ? 'Connected'
                          : widget.isIncoming
                              ? 'Incoming ${widget.isVideo ? 'Video ' : 'Voice '}Call'
                              : 'Calling...',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

            // Local Video (PiP)
            if (widget.isVideo && _localStream != null && !_isVideoOff)
              Positioned(
                top: 20,
                right: 20,
                width: 110,
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // Controls
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (widget.isIncoming && !_isCallAnswered) {
      // Incoming Call Controls
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.call_end_rounded,
            color: Colors.redAccent,
            onPressed: _rejectCall,
          ),
          _buildControlButton(
            icon: Icons.call_rounded,
            color: Colors.greenAccent.shade700,
            onPressed: _answerCall,
          ),
        ],
      );
    }

    // Active Call Controls
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            color: _isMuted ? Colors.white : AppColors.surface,
            iconColor: _isMuted ? AppColors.backgroundDark : Colors.white,
            onPressed: _toggleMute,
            small: true,
          ),
          _buildControlButton(
            icon: Icons.call_end_rounded,
            color: Colors.redAccent,
            iconColor: Colors.white,
            onPressed: _endCall,
          ),
          if (widget.isVideo)
            _buildControlButton(
              icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
              color: _isVideoOff ? Colors.white : AppColors.surface,
              iconColor: _isVideoOff ? AppColors.backgroundDark : Colors.white,
              onPressed: _toggleVideo,
              small: true,
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    Color iconColor = Colors.white,
    required VoidCallback onPressed,
    bool small = false,
  }) {
    final size = small ? 56.0 : 64.0;
    final iconSize = small ? 26.0 : 32.0;
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

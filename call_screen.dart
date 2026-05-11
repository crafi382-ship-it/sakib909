import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../constants/supabase_constants.dart';
import '../models/user_model.dart';

/// Full-screen voice/video call screen powered by ZegoCloud.
///
/// Usage — voice call:
///   startCall(context, currentUser: me, otherUser: them, isVideoCall: false);
///
/// Usage — video call:
///   startCall(context, currentUser: me, otherUser: them, isVideoCall: true);
class CallScreen extends StatelessWidget {
  final UserModel currentUser;
  final UserModel otherUser;
  final String callID;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
    required this.callID,
    this.isVideoCall = false,
  });

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: ZegoConstants.appID,
      appSign: ZegoConstants.appSign,
      // Current user identity
      userID: currentUser.id,
      userName: currentUser.username,
      // Unique room ID for this call
      callID: callID,
      // Voice call or video call config
      config: isVideoCall
          ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
          : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
    );
  }
}

/// Helper to push the [CallScreen] onto the navigator.
void startCall(
  BuildContext context, {
  required UserModel currentUser,
  required UserModel otherUser,
  required bool isVideoCall,
}) {
  // callID must be the same on both sides → use a sorted pair so
  // whichever user initiates gets the same room ID.
  final ids = [currentUser.id, otherUser.id]..sort();
  final callID = '${ids[0]}_${ids[1]}_${isVideoCall ? 'video' : 'voice'}';

  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => CallScreen(
      currentUser: currentUser,
      otherUser: otherUser,
      callID: callID,
      isVideoCall: isVideoCall,
    ),
  ));
}

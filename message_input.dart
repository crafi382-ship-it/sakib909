import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../models/message_model.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(File, MessageType, String?) onSendFile;
  final Function(bool) onTypingChanged;
  final MessageModel? replyMessage;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    required this.onSendText,
    required this.onSendFile,
    required this.onTypingChanged,
    this.replyMessage,
    this.onCancelReply,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _showEmoji = false;

  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _ctrl.clear();
    widget.onTypingChanged(false);
  }

  Future<void> _pickImage(ImageSource src) async {
    Navigator.pop(context);
    final picked = await ImagePicker().pickImage(source: src, imageQuality: 75);
    if (picked != null) widget.onSendFile(File(picked.path), MessageType.image, null);
  }

  Future<void> _pickVideo() async {
    Navigator.pop(context);
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) widget.onSendFile(File(picked.path), MessageType.video, null);
  }

  Future<void> _pickFile() async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final ext = result.files.single.name.split('.').last.toLowerCase();
      widget.onSendFile(file,
          ext == 'pdf' ? MessageType.pdf : MessageType.document,
          result.files.single.name);
    }
  }

  Future<void> _pickAudio() async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      widget.onSendFile(File(result.files.single.path!), MessageType.audio,
          result.files.single.name);
    }
  }

  void _showAttachSheet() => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1F2C34)
                : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _opt(Icons.camera_alt_rounded, 'Camera', const Color(0xFF3B82F6),
                  () => _pickImage(ImageSource.camera)),
              _opt(Icons.photo_library_rounded, 'Gallery',
                  const Color(0xFF8B5CF6),
                  () => _pickImage(ImageSource.gallery)),
              _opt(Icons.videocam_rounded, 'Video', const Color(0xFFF59E0B),
                  _pickVideo),
              _opt(Icons.insert_drive_file_rounded, 'Document',
                  const Color(0xFF10B981), _pickFile),
              _opt(Icons.headphones_rounded, 'Audio', const Color(0xFFEF4444),
                  _pickAudio),
            ]),
          ]),
        ),
      );

  Widget _opt(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      if (widget.replyMessage != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: isDark ? const Color(0xFF1F2C34) : const Color(0xFFECF3F8),
          child: Row(children: [
            Container(width: 3, height: 44, color: const Color(0xFF25D366)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Replying to',
                    style: TextStyle(
                        color: Color(0xFF25D366),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 2),
                Text(widget.replyMessage!.message,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20,
                  color: isDark ? Colors.white54 : Colors.black45),
              onPressed: widget.onCancelReply,
            ),
          ]),
        ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: isDark ? const Color(0xFF1F2C34) : Colors.white,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          IconButton(
            icon: Icon(
              _showEmoji
                  ? Icons.keyboard_rounded
                  : Icons.emoji_emotions_outlined,
              color: const Color(0xFF54656F), size: 26,
            ),
            onPressed: () {
              if (_showEmoji) _focus.requestFocus();
              else _focus.unfocus();
              setState(() => _showEmoji = !_showEmoji);
            },
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A3942)
                    : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111B21)),
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      hintStyle: TextStyle(color: Color(0xFF8696A0)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onChanged: (v) {
                      widget.onTypingChanged(v.isNotEmpty);
                      if (_showEmoji) setState(() => _showEmoji = false);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  child: IconButton(
                    icon: const Icon(Icons.attach_file_rounded,
                        color: Color(0xFF54656F)),
                    onPressed: _showAttachSheet,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 48, height: 48,
              decoration: const BoxDecoration(
                  color: Color(0xFF25D366), shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
      if (_showEmoji)
        SizedBox(
          height: 280,
          child: EmojiPicker(
            textEditingController: _ctrl,
            config: Config(
              height: 280,
              emojiViewConfig: EmojiViewConfig(
                  backgroundColor: isDark
                      ? const Color(0xFF1F2C34)
                      : Colors.white),
              categoryViewConfig: const CategoryViewConfig(
                  indicatorColor: Color(0xFF25D366),
                  iconColorSelected: Color(0xFF25D366)),
            ),
          ),
        ),
    ]);
  }
}

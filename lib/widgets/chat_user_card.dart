import 'package:flutter/material.dart';
import 'package:blu_tik/models/chat_user.dart';
import 'package:blu_tik/models/messages.dart';
import 'package:blu_tik/pages/chat_screen.dart';
import 'package:blu_tik/api/apis.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUserCard extends StatelessWidget {
  final ChatUser user;

  const ChatUserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: APIs.getLastmsgs(user),
      builder: (context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        String lastMessage = user.about; // Default: Show 'about' if no messages
        bool hasUnread = false;
        int lastMsgTime =
            _parseTimestamp(user.lastActive); // Default to lastActive

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var msgData = snapshot.data!.docs.first.data();
          Message lastMsg = Message.fromJson(msgData);

          lastMessage = lastMsg.type == Type.image ? "📷 Photo" : lastMsg.msg;
          lastMsgTime = _parseTimestamp(lastMsg.sent); // ✅ Use correct timestamp
          hasUnread = lastMsg.read.isEmpty && lastMsg.fromId != APIs.user.uid;
        }

        return ListTile(
          leading: _buildAvatar(user),
          title: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: lastMessage == "📷 Photo"
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          trailing: hasUnread
              ? _greenDot()
              : Text(_formatTime(lastMsgTime),
                  style: const TextStyle(color: Colors.grey)),
          onTap: () {
            print('Tapped on chat with ${user.name}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatUser: user),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatar(ChatUser user) {
    return user.image.isNotEmpty
        ? CircleAvatar(
            backgroundImage: NetworkImage(user.image),
            backgroundColor: Colors.transparent,
          )
        : CircleAvatar(
            backgroundColor: Colors.grey,
            child: Text(
              _getInitials(user.name),
              style: const TextStyle(color: Colors.white),
            ),
          );
  }

  Widget _greenDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    String initials = '';
    for (var part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
      }
    }
    return initials.isEmpty ? '?' : initials;
  }

  int _parseTimestamp(String timestamp) {
    try {
      return int.tryParse(timestamp) ?? 0;
    } catch (e) {
      print("❌ Invalid timestamp: $timestamp");
      return 0;
    }
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return "Unknown";

    try {
      DateTime lastActive = DateTime.fromMillisecondsSinceEpoch(timestamp);
      Duration diff = DateTime.now().difference(lastActive);

      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
      if (diff.inHours < 24)
        return "${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago";
      if (diff.inDays < 7)
        return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
      if (diff.inDays < 30)
        return "${(diff.inDays / 7).floor()} week${(diff.inDays / 7).floor() > 1 ? 's' : ''} ago";

      return "${(diff.inDays / 30).floor()} month${(diff.inDays / 30).floor() > 1 ? 's' : ''} ago";
    } catch (e) {
      print("❌ Error parsing timestamp: $e");
      return "Recently active"; // Fallback message
    }
  }
}

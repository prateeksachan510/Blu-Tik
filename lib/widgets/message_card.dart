import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blu_tik/api/apis.dart';
import 'package:blu_tik/helper/full_screen_image.dart';
import 'package:blu_tik/models/messages.dart';
import 'package:blu_tik/pages/colors.dart';

class MessageCard extends StatelessWidget {
  final Message message;
  final bool isSentByMe;
  final String time;
  final String isRead;
  final Function(Message) onReply;
  final Function(Message) onDelete;

  const MessageCard({
    super.key,
    required this.message,
    required this.isSentByMe,
    required this.time,
    required this.isRead,
    required this.onReply,
    required this.onDelete,
  });

  

  @override
  Widget build(BuildContext context) {
    // Mark as read only once
    if (!isSentByMe && message.read.isEmpty) {
      APIs.updateMessageReadStatus(message);
    }
    

    return GestureDetector(
      onLongPressStart: (details) =>
          _showMessageOptions(context, details.globalPosition),
      child: Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSentByMe
                ? const Color.fromARGB(255, 116, 88, 12)
                : AppColors.msgBack,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isSentByMe ? const Radius.circular(16) : Radius.zero,
              bottomRight: isSentByMe ? Radius.zero : const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.type == Type.text)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  child: Text(
                    message.msg,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                )
              else
                _buildImageMessage(context, message.msg),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(time),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(width: 5),
                  if (isSentByMe && isRead.isNotEmpty)
                    const Icon(
                      Icons.done_all,
                      size: 16,
                      color: Colors.blue,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImage(imageUrl: imageUrl),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image,
            size: 50,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      color: AppColors.appbarkC,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'reply',
          child: Row(
            children: const [
              Icon(Icons.reply, color: Colors.blue),
              SizedBox(width: 10),
              Text(
                'Reply',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: const [
              Icon(Icons.copy, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Copy',
                style: TextStyle(color: Colors.white),
              )
            ],
          ),
        ),
        if (isSentByMe)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: const [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                )
              ],
            ),
          ),
      ],
    ).then((value) {
      if (value == 'reply') {
        onReply(message);
      } else if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: message.msg));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message copied!')),
        );
      } else if (value == 'delete') {
        String chatId = getConversationID(message.fromId, message.toId);
        APIs.deleteMessage(message.id, chatId);
        onDelete(message);
      }
    });
  }

  String _formatTime(dynamic timestamp) {
    try {
      int millis;

      if (timestamp is int) {
        millis = timestamp;
      } else if (timestamp is String) {
        millis = int.tryParse(timestamp) ?? 0;
      } else {
        return "Invalid Time";
      }

      if (millis == 0) return "Invalid Time";

      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(millis);
      String period = dateTime.hour >= 12 ? "pm" : "am";
      int hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;

      return "$hour:${dateTime.minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return "Invalid Time";
    }
  }

  String getConversationID(String id1, String id2) {
    return id1.hashCode <= id2.hashCode ? '${id1}_$id2' : '${id2}_$id1';
  }

  
}

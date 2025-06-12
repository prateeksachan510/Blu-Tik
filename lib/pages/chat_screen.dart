import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blu_tik/api/apis.dart';
import 'package:blu_tik/models/chat_user.dart';
import 'package:blu_tik/models/messages.dart';
import 'package:blu_tik/pages/colors.dart';
import 'package:blu_tik/widgets/message_card.dart';
import 'package:blu_tik/pages/chat_user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser chatUser;

  const ChatScreen({super.key, required this.chatUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmoji = false;
  FocusNode _focusNode = FocusNode();
  String? _image;
  Message? _replyingTo; // Stores the message being replied to

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmoji = false; // Hide emoji picker when keyboard is opened
        });
      }
    });
    Future.delayed(Duration(milliseconds: 500), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300), // Smooth scroll
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.backC,
        appBar: AppBar(
          backgroundColor: AppColors.appbarkC,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatUserProfileScreen(chatUser: widget.chatUser),
                ),
              );
            },
            child: _buildAppBarTitle(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: APIs.getAllmsgs(widget.chatUser),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Say Hi!! 👋🏻',
                          style: TextStyle(color: AppColors.textC)),
                    );
                  }

                  final messages = snapshot.data!.docs
                      .map((doc) =>
                          Message.fromJson(doc.data() as Map<String, dynamic>))
                      .toList();
                  messages.sort((a, b) => a.sent
                      .compareTo(b.sent)); // ✅ Sort by time (latest at bottom)

                  // ✅ Group messages by day
                  Map<String, List<Message>> groupedMessages = {};
                  for (var msg in messages) {
                    String dateKey = _getDateKey(msg.sent);
                    if (!groupedMessages.containsKey(dateKey)) {
                      groupedMessages[dateKey] = [];
                    }
                    groupedMessages[dateKey]!.add(msg);
                  }

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());

                  return NotificationListener<OverscrollIndicatorNotification>(
                    onNotification: (overscroll) {
                      overscroll.disallowIndicator();
                      return true;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      itemCount: groupedMessages.keys.length,
                      itemBuilder: (context, index) {
                        String dateKey = groupedMessages.keys.elementAt(index);
                        List<Message> dayMessages = groupedMessages[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateHeader(dateKey),
                            ...dayMessages.map((message) => MessageCard(
                                  message: message,
                                  isSentByMe: message.fromId == APIs.user.uid,
                                  time: message.sent,
                                  isRead: message.read,
                                  onReply: _handleReply,
                                  onDelete: _handleDeleteMessage,
                                )),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            chatTools(),
            Offstage(
              offstage: !_showEmoji,
              child: SizedBox(
                height: 250,
                child: EmojiPicker(
                  textEditingController: _messageController,
                  config: Config(
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax: 28.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: APIs.getUserStatus(widget.chatUser.id),
      builder: (context, snapshot) {
        bool isOnline = false;
        String lastSeenText = "Last seen unknown";

        if (snapshot.hasData && snapshot.data?.data() != null) {
          var userData = snapshot.data!.data()!;
          isOnline = userData['isOnline'] ?? false;

          // Handle lastActive (which might be an int)
          if (!isOnline && userData['lastActive'] != null) {
            try {
              int lastActiveMillis = userData['lastActive'];
              lastSeenText = "Last seen ${_formatTime(lastActiveMillis)}";
            } catch (e) {
              lastSeenText = "Last seen recently";
            }
          } else if (isOnline) {
            lastSeenText = "Online";
          }
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(widget.chatUser.image),
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatUser.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  lastSeenText,
                  style: TextStyle(
                    color: isOnline ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget chatTools() {
    return Row(children: [
      Expanded(
        child: Card(
          color: AppColors.msgBack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _toggleEmojiPicker,
                icon: Icon(
                  _showEmoji
                      ? Icons.keyboard // Show keyboard icon when emoji is open
                      : Icons.emoji_emotions_outlined,
                  color: Colors.grey,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  cursorColor: AppColors.darkYellowC,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  focusNode: _focusNode, // Set the focus node
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.image, color: Colors.grey),
              ),
              IconButton(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt_rounded, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 5),
      MaterialButton(
        shape: const CircleBorder(),
        color: AppColors.darkYellowC,
        padding: const EdgeInsets.all(9),
        minWidth: 50,
        height: 50,
        onPressed: _sendMessage,
        child: const Icon(
          Icons.send,
          color: AppColors.appbarkC,
          size: 28,
        ),
      ),
      const SizedBox(width: 7),
    ]);
  }

  void _toggleEmojiPicker() {
    if (_showEmoji) {
      _focusNode.requestFocus(); // Open keyboard if emojis are showing
    } else {
      FocusScope.of(context).unfocus(); // Hide keyboard first
      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() {
          _showEmoji = true;
        });
      });
      return;
    }
    setState(() {
      _showEmoji = !_showEmoji;
    });
  }

  void _sendMessage() {
    String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      APIs.sendMessage(messageText, widget.chatUser, Type.text);
      _messageController.clear();
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }

  String _formatTime(int timestamp) {
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

  Future<void> _pickImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    String imagePath = pickedFile.path;

    if (_image == imagePath) {
      print("Same image selected, skipping upload.");
      return; // Prevent duplicate uploads
    }

    setState(() => _image = imagePath);

    // Upload to ImageKit
    String? uploadedUrl = await APIs.uploadChatImageToImageKit(
        imagePath, APIs.user.uid, widget.chatUser.id);
    if (uploadedUrl != null) {
      // Send image as a message
      APIs.sendMessage(uploadedUrl, widget.chatUser, Type.image);
    } else {
      print("❌ Failed to upload image");
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image == null) {
        debugPrint("❌ No image selected.");
        return;
      }

      debugPrint("📸 Image picked: ${image.path}");

      // Upload to ImageKit
      String? uploadedUrl = await APIs.uploadChatImageToImageKit(
          image.path, APIs.user.uid, widget.chatUser.id);

      if (uploadedUrl != null) {
        debugPrint("✅ Image uploaded successfully: $uploadedUrl");

        // Send image as a message
        APIs.sendMessage(uploadedUrl, widget.chatUser, Type.image);

        // Update UI if needed
        setState(() {
          _image = uploadedUrl; // Ensure `_image` is used correctly in your UI
        });
      } else {
        debugPrint("❌ Image upload failed.");
      }
    } catch (e) {
      debugPrint("⚠️ Error picking or uploading image: $e");
    }
  }

  void _handleReply(Message message) {
    setState(() {
      _replyingTo = message;
    });
  }

  void _handleDeleteMessage(Message message) async {
    await APIs.deleteMessage(message.id, widget.chatUser.id);
  }

  String _getDateKey(String timestamp) {
    DateTime msgDate =
        DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(Duration(days: 1));

    if (_isSameDay(msgDate, now)) return "Today";
    if (_isSameDay(msgDate, yesterday)) return "Yesterday";
    return "${msgDate.day} ${_getMonthName(msgDate.month)} ${msgDate.year}";
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthName(int month) {
    List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.appbarkC,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            date,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:blu_tik/api/apis.dart';
import 'package:blu_tik/helper/full_screen_image.dart';
import 'package:blu_tik/models/chat_user.dart';
import 'package:blu_tik/pages/colors.dart';
import 'package:blu_tik/widgets/friend_section_state.dart';

class ChatUserProfileScreen extends StatelessWidget {
  final ChatUser chatUser;

  const ChatUserProfileScreen({Key? key, required this.chatUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backC, // Apply dark background
      appBar: AppBar(
        title:
            Text(chatUser.name, style: const TextStyle(color: AppColors.textC)),
        backgroundColor: AppColors.appbarkC,
        iconTheme:
            const IconThemeData(color: AppColors.textC), // Back button color
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(chatUser.id)
            .snapshots(),
        builder: (context, snapshot) {
          bool isOnline = false;
          String lastSeenText = "Last seen unknown";

          if (snapshot.hasData && snapshot.data?.data() != null) {
            var userData = snapshot.data!.data()! as Map<String, dynamic>;
            isOnline = userData['isOnline'] ?? false;

            // Handle lastActive timestamp
            if (!isOnline && userData['lastActive'] != null) {
              try {
                int lastActiveMillis = userData['lastActive'];
                lastSeenText = "Last Active: ${_formatTime(lastActiveMillis)}";
              } catch (e) {
                lastSeenText = "Last seen recently";
              }
            } else if (isOnline) {
              lastSeenText = "Online";
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image with Full Screen View
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FullScreenImage(imageUrl: chatUser.image),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(chatUser.image),
                        backgroundColor: Colors.grey[300],
                      ),
                      // Online Status Indicator
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 6,
                            backgroundColor:
                                isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // User Name
                Text(
                  chatUser.name,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkYellowC),
                ),
                // Online Status Text
                Text(
                  lastSeenText,
                  style: TextStyle(
                    color: isOnline ? AppColors.secondaryC : AppColors.errorC,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                // Email
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email,
                        size: 16, color: AppColors.darkYellowC),
                    const SizedBox(width: 5),
                    Text(
                      chatUser.email,
                      style: const TextStyle(color: AppColors.textC),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // User ID (styled like other text)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.perm_identity,
                        size: 16, color: AppColors.darkYellowC),
                    const SizedBox(width: 5),
                    SelectableText(
                      "UID: ${chatUser.id}", // ✅ Prefix "UID:" with space
                      style: const TextStyle(color: AppColors.textC),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Joined Date (Formatted without time)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppColors.darkYellowC),
                    const SizedBox(width: 5),
                    Text(
                      "Joined: ${_formatDate(int.tryParse(chatUser.createdAt) ?? 0)}", // ✅ Fix type conversion issue
                      style: const TextStyle(color: AppColors.textC),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // About Section
                Text(
                  "About: ${chatUser.about}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.textC),
                ),
                const SizedBox(height: 50),

                // **Media Section**
                //Expanded(child: _buildMediaSection()),

                // **Friends Section**
                Expanded(
                  child: FriendsSection(chatUser: chatUser),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ Format timestamp to only show date (DD/MM/YYYY)
  String _formatDate(int timestamp) {
    if (timestamp == 0) return "Unknown"; // Handle invalid timestamps
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day}/${date.month}/${date.year}"; // ✅ No time, just date
  }

  // ✅ Format time (for last active)
  String _formatTime(int timestamp) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${time.hour}:${time.minute}, ${time.day}/${time.month}/${time.year}";
  }

  // // ✅ Fetch images from Firestore & Display
  // Widget _buildMediaSection() {
  //   return StreamBuilder<QuerySnapshot>(
  //     stream: FirebaseFirestore.instance
  //         .collection('chats')
  //         .doc(APIs.getConversationID(APIs.uid)) // Assuming chatUser.id is the chat ID
  //         .collection('messages')
  //         .where('type', isEqualTo: 'image') // Fetch only images
  //         .orderBy('timestamp', descending: true) // Sort newest first
  //         .snapshots(),
  //     builder: (context, snapshot) {
  //       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  //         return const Center(
  //           child: Text(
  //             "No Media Found",
  //             style: TextStyle(color: AppColors.textC),
  //           ),
  //         );
  //       }

  //       List<DocumentSnapshot> images = snapshot.data!.docs;

  //       return GridView.builder(
  //         padding: const EdgeInsets.only(top: 10),
  //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //           crossAxisCount: 3, // 3 images per row
  //           crossAxisSpacing: 4,
  //           mainAxisSpacing: 4,
  //         ),
  //         itemCount: images.length,
  //         itemBuilder: (context, index) {
  //           String imageUrl = images[index]['content']; // Assuming 'content' stores image URL

  //           return GestureDetector(
  //             onTap: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (_) => FullScreenImage(imageUrl: imageUrl),
  //                 ),
  //               );
  //             },
  //             child: ClipRRect(
  //               borderRadius: BorderRadius.circular(8),
  //               child: Image.network(imageUrl, fit: BoxFit.cover),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
}

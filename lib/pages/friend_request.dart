import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blu_tik/api/apis.dart';
import 'package:blu_tik/models/chat_user.dart';
import 'package:blu_tik/pages/chat_user_profile_screen.dart';
import 'package:blu_tik/pages/colors.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appbarkC, // Dark mode background
      appBar: AppBar(
        title: const Text(
          'Friend Requests',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: AppColors.appbarkC,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('friend_requests')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No friend requests found',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final friendRequests = snapshot.data!.docs
              .where((doc) =>
                  doc['to'] ==
                  currentUserId) // Show requests for the current user
              .toList();

          if (friendRequests.isEmpty) {
            return const Center(
              child: Text(
                'No friend requests for you.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: friendRequests.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemBuilder: (context, index) {
              final request = friendRequests[index];
              final requestData = request.data() as Map<String, dynamic>;
              final senderId = requestData['from'] ?? 'Unknown';

              return FutureBuilder(
                future: _getUserData(senderId),
                builder: (context,
                    AsyncSnapshot<Map<String, dynamic>?> userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final userData = userSnapshot.data;
                  final name = userData?['name'] ?? 'Unknown User';
                  final about = userData?['email'] ?? 'No Email';
                  final profilePic = userData?['image'] ??
                      'https://www.gravatar.com/avatar/placeholder?d=mp'; // Default profile pic

                  return Center(
                    child: GestureDetector(
                      onTap: () async {
                        ChatUser? chatUser =
                            await APIs.getChatUserById(senderId);
                        if (chatUser != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatUserProfileScreen(chatUser: chatUser),
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: MediaQuery.of(context).size.height *
                            0.1, // Narrower card width
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundImage: NetworkImage(profilePic),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    about,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    await APIs.acceptFriendRequest(
                                        request.id, senderId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Friend request accepted'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.check, size: 28),
                                  color: Colors.green,
                                  tooltip: "Accept",
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await APIs.declineFriendRequest(senderId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Friend request declined'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.close, size: 28),
                                  color: Colors.redAccent,
                                  tooltip: "Decline",
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

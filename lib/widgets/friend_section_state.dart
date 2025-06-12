import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:blu_tik/api/apis.dart';
import 'package:blu_tik/models/chat_user.dart';
import 'package:blu_tik/pages/colors.dart';

class FriendsSection extends StatefulWidget {
  final ChatUser chatUser;
  const FriendsSection({Key? key, required this.chatUser}) : super(key: key);

  @override
  _FriendsSectionState createState() => _FriendsSectionState();
}

class _FriendsSectionState extends State<FriendsSection> {
  Set<String> sentRequests = {}; // Track sent requests
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _fetchSentRequests();
  }

  Future<void> _fetchSentRequests() async {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await APIs.getUserByUID(currentUserId);
    setState(() {
      sentRequests = Set<String>.from(userDoc['sent_requests'] ?? []);
    });
  }

  Future<void> _addFriend(BuildContext context, ChatUser user) async {
    if (sentRequests.contains(user.id)) return;

    await APIs.sendFriendRequest(user.id);
    setState(() {
      sentRequests.add(user.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Friend request sent!'),
        backgroundColor: AppColors.IappbarkC,
      ),
    );
  }

  Future<void> _cancelFriendRequest(BuildContext context, ChatUser user) async {
    await APIs.cancelFriendRequest(user.id);
    setState(() {
      sentRequests.remove(user.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Friend request canceled!'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  Widget _buildFriendButton(ChatUser user) {
    bool isRequestSent = sentRequests.contains(user.id);

    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor:
            isRequestSent ? Colors.grey[600] : AppColors.darkYellowC,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () => isRequestSent
          ? _cancelFriendRequest(context, user)
          : _addFriend(context, user),
      icon: Icon(isRequestSent ? Icons.close : Icons.person_add, size: 18),
      label: Text(isRequestSent ? "Cancel" : "Add",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Future<List<ChatUser>> _fetchFriendsDetails(List<String> friendIds) async {
    if (friendIds.isEmpty) return []; // If no friends, return empty list

    try {
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: friendIds)
          .get();

      return usersSnapshot.docs.map((doc) {
        return ChatUser.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print("Error fetching friends: $e");
      return [];
    }
  }

  Widget _buildFriendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // **Header Title**
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Text(
            "Friends",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.darkYellowC,
            ),
          ),
        ),
        Expanded(
          child: widget.chatUser.friends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_alt_1,
                          size: 50, color: AppColors.textC),
                      const SizedBox(height: 10),
                      Text(
                        "No Friends Yet",
                        style: TextStyle(fontSize: 16, color: AppColors.textC),
                      ),
                    ],
                  ),
                )
              : FutureBuilder<List<ChatUser>>(
                  future: _fetchFriendsDetails(widget.chatUser.friends),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<ChatUser> friendsList = snapshot.data!;

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: friendsList.length,
                      itemBuilder: (context, index) {
                        ChatUser friend = friendsList[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: AppColors.IappbarkC.withOpacity(0.1),
                          child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 8),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(friend.image),
                              ),
                              title: Text(
                                friend.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textC,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                friend.email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.secondaryC,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: friend.id == currentUserId
                                  ? null
                                  : _buildFriendButton(friend)),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildFriendsSection();
  }
}

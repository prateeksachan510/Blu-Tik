import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:blu_tik/api/apis.dart';
import 'package:blu_tik/models/chat_user.dart';
import 'package:blu_tik/pages/colors.dart';

class AddFriend {
  static void addFriend(BuildContext context) {
    TextEditingController inputController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.backC,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Find a Friend',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textC,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: inputController,
                    style: const TextStyle(color: AppColors.textC),
                    decoration: InputDecoration(
                      hintText: 'Enter UID or Email',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: AppColors.darkYellowC),
                      filled: true,
                      fillColor: AppColors.msgBack,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isLoading)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.darkYellowC),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    inputController.dispose();
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkYellowC,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    String input = inputController.text.trim();
                    if (input.isEmpty) return;

                    setState(() => isLoading = true);

                    try {
                      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

                      QuerySnapshot<Map<String, dynamic>> query;

                      if (input.contains("@")) {
                        // 🔍 **Search by Email (Case-insensitive)**
                        query = await FirebaseFirestore.instance
                            .collection('users')
                            .where('email', isEqualTo: input.toLowerCase())
                            .limit(1)
                            .get();
                      } else {
                        // 🔍 **Search by UID**
                        query = await FirebaseFirestore.instance
                            .collection('users')
                            .where('id', isEqualTo: input)
                            .limit(1)
                            .get();
                      }

                      setState(() => isLoading = false);

                      if (query.docs.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User not found!'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      ChatUser user = ChatUser.fromJson(query.docs.first.data());

                      Navigator.pop(context); // Close input dialog

                      // Show user info dialog
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: AppColors.backC,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'User Found',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textC,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(user.image),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textC,
                                  ),
                                ),
                                Text(
                                  user.about,
                                  style: TextStyle(color: Colors.grey.shade400),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.darkYellowC,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.person_add,
                                    color: AppColors.ItextC,
                                  ),
                                  label: const Text(
                                    'Send Friend Request',
                                    style: TextStyle(color: AppColors.ItextC),
                                  ),
                                  onPressed: () async {
                                    // 🛑 **Prevent adding yourself**
                                    if (user.id == currentUserId) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("You can't add yourself!"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // 🛑 **Prevent duplicate friend request**
                                    DocumentSnapshot<Map<String, dynamic>> currentUserDoc =
                                        await APIs.getUserByUID(currentUserId);
                                    List<String> currentUserFriends =
                                        List<String>.from(currentUserDoc['friends'] ?? []);

                                    if (currentUserFriends.contains(user.id)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('This user is already your friend!'),
                                          backgroundColor: AppColors.IappbarkC,
                                        ),
                                      );
                                      return;
                                    }

                                    // ✅ **Send Friend Request**
                                    await APIs.sendFriendRequest(user.id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Friend request sent!'),
                                        backgroundColor: AppColors.IappbarkC,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    } catch (e) {
                      setState(() => isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Search',
                    style: TextStyle(color: AppColors.ItextC),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

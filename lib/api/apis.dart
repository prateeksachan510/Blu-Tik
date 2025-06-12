import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:blu_tik/models/chat_user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:blu_tik/models/messages.dart';

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static const String imageKitUploadUrl =
      "https://upload.imagekit.io/api/v1/files/upload";
  static const String imageKitDeleteUrl = "https://api.imagekit.io/v1/files/";
  static const String privateKey = "private_idr3vekvJnfc3YNmk8qYCOltPvw=";

  static User get user => auth.currentUser!;
  static String uid = user.uid;

  static Future<bool> userExists() async {
    return (await firestore
            .collection('users')
            .doc(auth.currentUser!.uid) // write user instead auth.currentUser
            .get())
        .exists;
  }

  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatuser = ChatUser(
        image: user.photoURL.toString(),
        name: user.displayName.toString(),
        about: 'Just a ping away! 🚀',
        createdAt: time,
        lastActive: time,
        isOnline: false,
        id: user.uid,
        pushToken: '',
        email: user.email.toString());
    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatuser.toJson());
  }

  static Future<ChatUser> getChatUser() async {
    final docSnapshot =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();
    if (docSnapshot.exists) {
      return ChatUser.fromJson(docSnapshot.data() as Map<String, dynamic>);
    } else {
      throw Exception("User not found in Firestore");
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  static Future<void> updateProfileImage(String imagePath) async {
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(user.uid).get();
      String? oldImageUrl = userDoc['image'];

      if (oldImageUrl == imagePath) {
        print("Same image detected, skipping update.");
        return;
      }

      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteOldImageFromImageKit(oldImageUrl);
      }

      String? newImageUrl = await uploadImageToImageKit(imagePath);

      if (newImageUrl != null) {
        await firestore.collection('users').doc(user.uid).update({
          'image': newImageUrl,
        });
      }
    } catch (e) {
      print("Error updating profile image: $e");
    }
  }

  static Future<void> deleteOldImageFromImageKit(String imageUrl) async {
    try {
      String fileId = extractFileIdFromUrl(imageUrl);
      var response = await http.delete(
        Uri.parse('$imageKitDeleteUrl$fileId'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$privateKey:'))}',
        },
      );

      if (response.statusCode == 200) {
        print("Old image deleted successfully.");
      } else {
        print("Failed to delete old image: ${response.body}");
      }
    } catch (e) {
      print("Error deleting old image: $e");
    }
  }

  static Future<String?> uploadImageToImageKit(String imagePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(imageKitUploadUrl))
        ..headers['Authorization'] =
            'Basic ${base64Encode(utf8.encode('$privateKey:'))}'
        ..fields['fileName'] =
            'profile_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ..fields['folder'] = '/profile_pictures' // Folder in ImageKit
        ..files.add(await http.MultipartFile.fromPath('file', imagePath));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);
        return jsonResponse['url']; // ✅ Return uploaded image URL
      } else {
        print('Failed to upload image: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  static String extractFileIdFromUrl(String imageUrl) {
    Uri uri = Uri.parse(imageUrl);
    String lastSegment = uri.pathSegments.last;

    if (lastSegment.contains('?')) {
      lastSegment = lastSegment.split('?')[0]; // Remove query params
    }

    return lastSegment; // Ensure you're getting the correct file ID
  }

  static Future<bool> updateUserProfileImage(String imageUrl) async {
    try {
      await firestore.collection('users').doc(user.uid).update({
        'image': imageUrl,
      });
      return true;
    } catch (e) {
      print("Error updating user profile image: $e");
      return false;
    }
  }

  static Future<bool> updateUserInfo(String name, String about,
      {String? imageUrl}) async {
    try {
      Map<String, dynamic> data = {
        'name': name,
        'about': about,
      };

      if (imageUrl != null) {
        data['image'] = imageUrl;
      }

      await firestore.collection('users').doc(user.uid).update(data);
      return true;
    } catch (e) {
      print("Error updating user info: $e");
      return false;
    }
  }

  static Future<void> updateLastSeen(bool isOnline) async {
    await firestore.collection('users').doc(user.uid).update({
      'isOnline': isOnline,
      'lastActive': isOnline
          ? FieldValue.serverTimestamp()
          : DateTime.now().millisecondsSinceEpoch, // Corrected field name
    });
  }

  static Future<void> updateUserStatus(bool isOnline) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastActive': isOnline ? null : DateTime.now().millisecondsSinceEpoch,
    });
  }

  //=====================================================================
  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllmsgs(
      ChatUser chatUser) {
    return firestore
        .collection('chats')
        .doc(getConversationID(chatUser.id))
        .collection('messages')
        .orderBy('sent', descending: false)
        .snapshots();
  }

  // chats Collection -> convo_id -> msgs(Collection) -> msg

  static Future<void> sendMessage(
      String msg, ChatUser chatUser, Type type) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages')
        .doc(); // 🔥 Get auto-generated ID

    final Message message = Message(
        id: ref.id, // 🔥 Store Firestore document ID
        toId: chatUser.id,
        msg: msg,
        read: '',
        type: type,
        sent: time,
        fromId: user.uid);

    await ref.set(message.toJson()); // 🔥 Save with ID
  }

  static Future<void> updateMessageReadStatus(Message msg) async {
    final query = await firestore
        .collection('chats/${getConversationID(msg.fromId)}/messages')
        .where('sent', isEqualTo: msg.sent)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'read': DateTime.now().microsecondsSinceEpoch.toString(),
      });
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastmsgs(
      ChatUser chatUser) {
    return firestore
        .collection('chats')
        .doc(getConversationID(chatUser.id))
        .collection('messages')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<String?> uploadChatImageToImageKit(
      String imagePath, String fromId, String toId) async {
    try {
      // Generate Conversation ID
      String chatId = getConversationID_forNamingFolder(fromId, toId);

      // Set Folder Path to Store Images in Chat-Specific Folders
      String folderPath = '/chat_images/$chatId/';

      var request = http.MultipartRequest('POST', Uri.parse(imageKitUploadUrl))
        ..headers['Authorization'] =
            'Basic ${base64Encode(utf8.encode('$privateKey:'))}'
        ..fields['fileName'] =
            'chat_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ..fields['folder'] = folderPath // Upload in specific chat folder
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          imagePath,
        ));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);
        return jsonResponse['url']; // ✅ Return uploaded image URL
      } else {
        print('❌ Failed to upload chat image: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading chat image: $e');
      return null;
    }
  }

  static String getConversationID_forNamingFolder(String id1, String id2) {
    return id1.hashCode <= id2.hashCode ? '${id1}_$id2' : '${id2}_$id1';
  }

  static Future<void> deleteMessage(String messageId, String chatId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      print("✅ Message deleted successfully");
    } catch (e) {
      print("❌ Error deleting message: $e");
    }
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStatus(
      String userId) {
    return firestore.collection('users').doc(userId).snapshots();
  }

  

//====================================================================================================================================

  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserByUID(
      String uid) async {
    return await FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  static Future<void> sendFriendRequest(String receiverUID) async {
    String senderUID = APIs.auth.currentUser!.uid;

    DocumentReference requestRef = FirebaseFirestore.instance
        .collection('friend_requests')
        .doc('$senderUID\_$receiverUID');

    await requestRef.set({
      'from': senderUID,
      'to': receiverUID,
      'status':
          'pending', // You can later update it to 'accepted' or 'declined'
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getFriendRequests() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('receiverId',
            isEqualTo: userId) // Only get requests for logged-in user
        .where('status', isEqualTo: 'pending') // Ensure they are pending
        .get();

    print('Fetched Requests: ${snapshot.docs.length}'); // Debugging

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id, // Store Firestore document ID for later use
        ...doc.data(), // Spread all other fields
      };
    }).toList();
  }

  // Accept a friend request
  static Future<void> acceptFriendRequest(
      String requestId, String senderId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final senderRef =
        FirebaseFirestore.instance.collection('users').doc(senderId);

    // Update both users' friend lists
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final senderDoc = await transaction.get(senderRef);

      if (userDoc.exists && senderDoc.exists) {
        List<String> userFriends = List<String>.from(userDoc['friends'] ?? []);
        List<String> senderFriends =
            List<String>.from(senderDoc['friends'] ?? []);

        if (!userFriends.contains(senderId)) userFriends.add(senderId);
        if (!senderFriends.contains(userId)) senderFriends.add(userId);

        transaction.update(userRef, {'friends': userFriends});
        transaction.update(senderRef, {'friends': senderFriends});
      }
    });

    // Remove the friend request
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(requestId)
        .delete();
  }

  // Decline a friend request
  static Future<void> declineFriendRequest(String senderId) async {
    String currentUserId = auth.currentUser!.uid;

    await firestore
        .collection('friend_requests')
        .doc(senderId + '_' + currentUserId)
        .delete();
  }

  static Future<ChatUser?> getChatUserById(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) return null; // Return null if user doesn't exist

      final data = userDoc.data()!;
      return ChatUser.fromJson(data);
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }
  
  // Remove friends id from list
  static Future<void> cancelFriendRequest(String friendId) async {
    String currentUserId = auth.currentUser!.uid;

    DocumentReference currentUserRef = firestore.collection('users').doc(currentUserId);
    DocumentReference friendRef = firestore.collection('users').doc(friendId);

    await firestore.runTransaction((transaction) async {
      // ✅ Remove friendId from currentUser's sent_requests
      transaction.update(currentUserRef, {
        'sent_requests': FieldValue.arrayRemove([friendId])
      });

      // ✅ Remove currentUserId from friend's received_requests
      transaction.update(friendRef, {
        'received_requests': FieldValue.arrayRemove([currentUserId])
      });
    });
  }
}

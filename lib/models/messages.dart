import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  Message({
    required this.id,
    required this.toId,
    required this.msg,
    required this.read,
    required this.type,
    required this.sent,
    required this.fromId,
  });

  late final String id;
  late final String toId;
  late final String msg;
  late final String read;
  late final Type type;
  late final String sent; 
  late final String fromId;

  Message.fromJson(Map<String, dynamic> json) {
  id = json['id'].toString();
  toId = json['toId'].toString();
  msg = json['msg'].toString();
  read = json['read'].toString();
  type = json['type'].toString() == Type.image.name ? Type.image : Type.text;
  fromId = json['fromId'].toString();

  // ✅ Convert Firestore Timestamp to milliseconds if needed
  if (json['sent'] is int) {
    sent = json['sent'].toString(); // Direct int to String
  } else if (json['sent'] is String) {
    sent = (int.tryParse(json['sent']) ?? 0).toString(); // Convert String to int
  } else if (json['sent'] is Timestamp) {
    sent = json['sent'].millisecondsSinceEpoch.toString(); // Convert Firestore Timestamp
  } else {
    sent = "0"; // Default to zero if invalid
  }
}


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toId': toId,
      'msg': msg,
      'read': read,
      'type': type.name,
      'sent': sent, // ✅ Store timestamp correctly
      'fromId': fromId,
    };
  }
}

enum Type { text, image }

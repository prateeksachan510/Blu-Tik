class ChatUser {
  ChatUser({
    required this.image,
    required this.name,
    this.about = "New here, let’s connect!", // Default about text
    required this.createdAt,
    required this.lastActive,
    required this.isOnline,
    required this.id,
    required this.pushToken,
    required this.email,
    this.friends = const [],
    this.sentRequests = const [],
    this.receivedRequests = const [],
  });

  late final String image;
  late final String name;
  late final String about;
  late final String createdAt;
  late final String lastActive;
  late final bool isOnline;
  late final String id;
  late final String pushToken;
  late final String email;
  late List<String> friends;          // Stores UIDs of accepted friends
  late List<String> sentRequests;     // Stores UIDs of users this user sent requests to
  late List<String> receivedRequests; // Stores UIDs of users who sent requests to this user

  ChatUser.fromJson(Map<String, dynamic> json) {
    image = json['image'] ?? '';
    name = json['name'] ?? '';
    about = json['about'] ?? "Just a ping away! 🚀"; // Default if null
    createdAt = json['created_at'] ?? '';
    lastActive = json['last_active'] ?? '';
    isOnline = json['is_online'] is bool 
      ? json['is_online'] 
      : (json['is_online'] == 'true');
    id = json['id'] ?? '';
    pushToken = json['push_token'] ?? '';
    email = json['email'] ?? '';
    friends = List<String>.from(json['friends'] ?? []);
    sentRequests = List<String>.from(json['sent_requests'] ?? []);
    receivedRequests = List<String>.from(json['received_requests'] ?? []);
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['image'] = image;
    _data['name'] = name;
    _data['about'] = about;
    _data['created_at'] = createdAt;
    _data['last_active'] = lastActive;
    _data['is_online'] = isOnline;
    _data['id'] = id;
    _data['push_token'] = pushToken;
    _data['email'] = email;
    _data['friends'] = friends;
    _data['sent_requests'] = sentRequests;
    _data['received_requests'] = receivedRequests;
    return _data;
  }

  ChatUser copyWith({
    String? image,
    String? name,
    String? about,
    String? createdAt,
    String? lastActive,
    bool? isOnline,
    String? id,
    String? pushToken,
    String? email,
    List<String>? friends,
    List<String>? sentRequests,
    List<String>? receivedRequests,
  }) {
    return ChatUser(
      image: image ?? this.image,
      name: name ?? this.name,
      about: about ?? this.about,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
      id: id ?? this.id,
      pushToken: pushToken ?? this.pushToken,
      email: email ?? this.email,
      friends: friends ?? this.friends,
      sentRequests: sentRequests ?? this.sentRequests,
      receivedRequests: receivedRequests ?? this.receivedRequests,
    );
  }
}

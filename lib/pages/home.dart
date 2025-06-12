import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:blu_tik/api/apis.dart';
import 'package:blu_tik/helper/add_friend.dart';
import 'package:blu_tik/models/chat_user.dart';
import 'package:blu_tik/pages/colors.dart';
import 'package:blu_tik/widgets/chat_user_card.dart';
import 'package:blu_tik/widgets/pop_up.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<ChatUser> chats = [];
  GlobalKey _menuKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 1,
          title: const Text(
            'Chat',
            style: TextStyle(
              color: AppColors.darkYellowC,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          backgroundColor: AppColors.appbarkC,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textC),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textC),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: ChatSearchDelegate(chats: chats),
                );
              },
            ),
            IconButton(
              key: _menuKey,
              icon: const Icon(Icons.more_vert, color: AppColors.textC),
              onPressed: () {
                final RenderBox button =
                    _menuKey.currentContext!.findRenderObject() as RenderBox;
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;

                final Offset position =
                    button.localToGlobal(Offset.zero, ancestor: overlay);

                final PopUP popUp = PopUP(); // ✅ Create an instance

                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    position.dx,
                    position.dy + button.size.height,
                    position.dx + button.size.width,
                    position.dy + button.size.height * 2,
                  ),
                  color: AppColors.msgBack, // Dark theme
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  items: [
                    popUp.buildPopupMenuItem('Profile', Icons.person,
                        AppColors.darkYellowC, Colors.white),
                    popUp.buildPopupMenuItem('Friend Requests', Icons.group,
                        AppColors.darkYellowC, Colors.white),
                    popUp.buildPopupMenuItem(
                        'Help', Icons.help_outline, Colors.blue, Colors.white),
                    popUp.buildPopupMenuItem(
                        'Logout', Icons.exit_to_app, Colors.red, Colors.red),
                  ],
                ).then((selected) {
                  if (selected != null) {
                    popUp.handleMenuSelection(
                        context, selected); // ✅ Call using instance
                  }
                });
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: AppColors.backC,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: AppColors.appbarkC),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'SamChat',
                      style: TextStyle(
                        color: AppColors.textC,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Welcome!',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: AppColors.textC),
                title: const Text('Home',
                    style: TextStyle(color: AppColors.textC)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.group, color: AppColors.textC),
                title: const Text('Groups',
                    style: TextStyle(color: AppColors.textC)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.info, color: AppColors.textC),
                title: const Text('About',
                    style: TextStyle(color: AppColors.textC)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        body: Container(
          color: const Color.fromARGB(255, 255, 255, 255),
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: APIs.getUserByUID(APIs.user.uid), // Fetch current user data
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const Center(
                  child: Text(
                    'No user data found!',
                    style: TextStyle(color: AppColors.textC),
                  ),
                );
              }

              List<String> friendIds =
                  List<String>.from(userSnapshot.data!['friends'] ?? []);

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: APIs.getAllUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(
                      child: Text(
                        'No users found!',
                        style: TextStyle(color: AppColors.textC),
                      ),
                    );
                  }

                  final querySnapshot = snapshot.data!;
                  final data =
                      querySnapshot.docs.map((doc) => doc.data()).toList();

                  // Filter users who are in the friend list
                  chats = data
                      .map((e) => ChatUser.fromJson(e))
                      .where((user) => friendIds.contains(user.id))
                      .toList();

                  if (chats.isNotEmpty) {
                    return ListView.builder(
                      itemCount: chats.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return ChatUserCard(user: chat);
                      },
                    );
                  } else {
                    return const Center(
                      child: Text(
                        'No Friends Found!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          elevation: 5,
          backgroundColor: AppColors.darkYellowC,
          child: const Icon(Icons.add_comment_rounded, color: Colors.white),
          onPressed: () => AddFriend.addFriend(context),
        ),
      ),
    );
  }
}

class ChatSearchDelegate extends SearchDelegate {
  final List<ChatUser> chats;

  ChatSearchDelegate({required this.chats});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appbarkC, // Dark app bar
        elevation: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.white),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = chats
        .where((chat) =>
            chat.name.toLowerCase().contains(query.toLowerCase()) ||
            chat.about.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      color: AppColors.backC, // Dark background
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final chat = results[index];
          return ChatUserCard(user: chat);
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

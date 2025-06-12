import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:blu_tik/api/apis.dart';

class PopUP {
  // Build a single menu item
  PopupMenuItem<String> buildPopupMenuItem(
      String text, IconData icon, Color iconColor, Color textColor) {
    return PopupMenuItem(
      value: text,
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  // Handle menu selection
  void handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'Profile':
        _openProfile(context);
        break;
      case 'Logout':
        _logoutUser(context);
        break;
      case 'Help':
        _showHelpDialog(context);
        break;
      case 'Friend Requests':
        _openFriendRequestPage(context);
        break;
    }
  }

  // Open profile page
  Future<void> _openProfile(BuildContext context) async {
    final chatUser = await APIs.getChatUser();
    Navigator.pushNamed(
      context,
      '/ProfileScreen',
      arguments: chatUser, // Pass the ChatUser
    );
    print('Profile button pressed');
  }

  // Logout user
  Future<void> _logoutUser(BuildContext context) async {
    await APIs.auth.signOut();
    await GoogleSignIn().signOut().then((_) async {
      Navigator.pop(context);
      await Navigator.pushReplacementNamed(context, '/getstarted');
    });
    print('Logged out!');
  }

  // Show help dialog
  void _showHelpDialog(BuildContext context) {
    print('Help button pressed');
  }

  Future<void> _openFriendRequestPage(BuildContext context) async {
    try {
      Navigator.pushNamed(context, '/FriendRequestsPage');
      print('Friend Requests button pressed');
    } catch (e) {
      print('Error opening friend requests: $e');
    }
  }
}

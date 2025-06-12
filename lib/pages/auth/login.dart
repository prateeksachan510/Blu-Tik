import 'dart:developer'; // For logging
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart'; // To get the current locale
import 'package:blu_tik/api/apis.dart';
import 'package:blu_tik/helper/dialogs.dart';
import 'package:blu_tik/pages/home.dart'; // Your HomeScreen path

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _zoomAnimation;
  late Animation<Offset> _moveUpAnimation;

  @override
  void initState() {
    super.initState();

    // Set the locale for Firebase
    setFirebaseLocale();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Define logo animations
    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _moveUpAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.25)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void setFirebaseLocale() {
    // Get the current device locale
    String locale = Intl.getCurrentLocale(); // e.g., "en_US"
    APIs.auth
        .setLanguageCode(locale); // Set the locale for Firebase authentication
  }

  _handleGoogleBtnClick() {
    Dialogs.showProgressBar(context); //for showing progress bar
    _signInWithGoogle().then((user) async {
      Navigator.pop(context); //for removing progress bar
      if (user != null) {
        log('\nUser: ${user.user}');
        log('\nUserAdditionalInfo: ${user.additionalUserInfo}');

        if ((await APIs.userExists())) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          await APIs.createUser().then((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          });
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Sign in to Firebase with the credential
      return await APIs.auth.signInWithCredential(credential);
    } catch (e) {
      log('Google Sign-In failed: $e');
      Dialogs.showSnackbar(context, 'Google Sign-In failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Updated background color to match logo
          Container(
            color: const Color(0xFF1F2937), // Dark Gray-Blue from logo
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
          ),

          // Back button to navigate back
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 28, color: Colors.white),
              onPressed: () {
                Navigator.pop(context); // Navigate back to the Get Started page
              },
            ),
          ),

          // Animated logo movement and zoom
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _zoomAnimation.value,
                child: SlideTransition(
                  position: _moveUpAnimation,
                  child: Align(
                    alignment: Alignment.center,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 170.0),

                          child: SvgPicture.asset(
                            'images/bluTik6.svg',
                            height: 150,
                            width: 150,
                          ),

                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Google Login button
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _handleGoogleBtnClick,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Bright yellow from logo
                  side: BorderSide(color: Colors.grey.shade300),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  shape: const StadiumBorder(),
                ),
                icon: Image.asset(
                  'images/google_logo.png',
                  height: 24,
                  width: 24,
                ),
                label: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Log in using ',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      TextSpan(
                        text: 'Google',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blu_tik/api/apis.dart';
import 'package:blu_tik/pages/auth/profile_screen.dart';
import 'package:blu_tik/pages/colors.dart';
import 'package:blu_tik/pages/friend_request.dart';
import 'package:blu_tik/pages/home.dart';
import 'package:blu_tik/pages/auth/getstart.dart';
import 'package:blu_tik/pages/auth/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:blu_tik/pages/splashScreen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LifecycleHandler(child: MyApp()));
}

class LifecycleHandler extends StatefulWidget {
  final Widget child;

  const LifecycleHandler({Key? key, required this.child}) : super(key: key);

  @override
  _LifecycleHandlerState createState() => _LifecycleHandlerState();
}

class _LifecycleHandlerState extends State<LifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateUserStatus(true); // Set user online when app starts
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateUserStatus(true); // App comes to foreground
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateUserStatus(false); // App goes to background
    }
  }

  void _updateUserStatus(bool isOnline) {
    if (FirebaseAuth.instance.currentUser != null) {
      APIs.updateUserStatus(isOnline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SamChat',
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.darkYellowC,
          selectionColor: AppColors.darkYellowC.withOpacity(0.5),
          selectionHandleColor: AppColors.darkYellowC,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/getstarted': (context) => const GetStartedScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/ProfileScreen': (context) => const ProfileScreen(),
        '/FriendRequestsPage': (context) => FriendRequestsPage(),
      },
    );
  }
}

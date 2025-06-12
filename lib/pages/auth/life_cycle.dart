import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:blu_tik/api/apis.dart';

class LifecycleHandler extends StatefulWidget {
  final Widget child;

  const LifecycleHandler({Key? key, required this.child}) : super(key: key);

  @override
  _LifecycleHandlerState createState() => _LifecycleHandlerState();
}

class _LifecycleHandlerState extends State<LifecycleHandler> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is active again
      APIs.updateUserStatus(true); // Set user online
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App goes to background or is closed
      APIs.updateUserStatus(false); // Set user offline & update lastActive
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

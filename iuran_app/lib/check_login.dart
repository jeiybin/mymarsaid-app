import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';
import 'pages/admin/home_admin.dart';
import 'pages/warga/home_warga.dart';

class CheckLoginPage extends StatefulWidget {
  const CheckLoginPage({super.key});

  @override
  State<CheckLoginPage> createState() => _CheckLoginPageState();
}

class _CheckLoginPageState extends State<CheckLoginPage> {

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {

    final prefs =
        await SharedPreferences.getInstance();

    bool isLogin =
        prefs.getBool("isLogin") ?? false;

    String role =
        prefs.getString("role") ?? "";

    if (!mounted) return;

    if (!isLogin) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(),
        ),
      );

      return;
    }

    if (role == "admin") {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeAdmin(),
        ),
      );

    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeWarga(),
        ),
      );

    }

  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
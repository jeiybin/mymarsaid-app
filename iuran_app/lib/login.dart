import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iuran_app/api.dart';
import 'pages/warga/home_warga.dart';
import 'pages/admin/home_admin.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool isLoading = false; // 🔥 untuk loading

  // FUNGSI LOGIN
  Future<void> loginUser() async {
    try {
      setState(() {
        isLoading = true;
      });

      final url = Uri.parse("${Api.baseUrl}/login");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "username": username.text,
          "password": password.text,
        }),
      );

      print("Response Login: ${response.body}");

      final data = jsonDecode(response.body);

      setState(() {
        isLoading = false;
      });

      if (data["status"] == "success") {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool("isLogin", true);

        await prefs.setInt(
          "id",
          data["user"]["id"],
        );

        await prefs.setString(
          "username",
          data["user"]["username"],
        );

        await prefs.setString(
          "role",
          data["user"]["role"],
        );

        if (data["user"]["id_warga"] != null) {
          await prefs.setInt(
            "id_warga",
            data["user"]["id_warga"],
          );
        }

        // =========================
        // AMBIL FCM TOKEN
        // =========================

        String? token = await FirebaseMessaging.instance.getToken();

        print("==================================");
        print("FCM TOKEN");
        print(token);
        print("==================================");

        // =========================
        // SIMPAN TOKEN KE FLASK
        // =========================

        final responseToken = await http.post(
          Uri.parse("${Api.baseUrl}/save_fcm_token"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "id": data["user"]["id"],
            "token": token,
          }),
        );

        print("Response Save Token:");
        print(responseToken.body);

        // =========================
        // PINDAH HALAMAN
        // =========================

        if (data["user"]["role"] == "admin") {
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      print("ERROR LOGIN");
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tidak bisa konek ke server",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100),

              // TITLE
              Text(
                "LOGIN",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 30),

              // USERNAME
              TextField(
                controller: username,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 15),

              // PASSWORD
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 20),

              // BUTTON LOGIN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Login"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

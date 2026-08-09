import 'package:flutter/material.dart';
import 'package:iuran_app/pages/warga/profil_saya.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iuran_app/login.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iuran_app/services/whatsapp.dart';


import 'home_warga.dart';
import 'pengumuman.dart';
import 'profil_saya.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String namaPengurus = "";
  String nomorPengurus = "";

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // HEADER
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 40,
                ),
                SizedBox(height: 10),
                Text(
                  "MyMarsaid",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // PROFILE
          drawerItem(
            context,
            Icons.person,
            "Profil Saya",
            ProfilWarga(),
          ),

          // DASHBOARD
          drawerItem(
            context,
            Icons.dashboard,
            "Dashboard",
            HomeWarga(),
          ),

          Divider(),

          // PENGUMUMAN
          drawerItem(
            context,
            Icons.campaign,
            "Pengumuman",
            PengumumanWarga(),
          ),

          // CHAT PENGURUS
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text("Chat Pengurus"),
            onTap: () {
              WhatsappService.chatPengurus(context);
            },
          ),


          // LOGOUT
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () async {
              final yakin = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: const Text("Logout"),
                    content: const Text(
                      "Apakah Anda yakin ingin keluar dari akun ini?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text("Batal"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (yakin != true) return;
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginPage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // DRAWER ITEM
  Widget drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iuran_app/pages/admin/agenda_page.dart';
import 'package:iuran_app/pages/admin/pengumuman_page.dart';
import 'package:iuran_app/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_admin.dart';
import 'data_warga.dart';
import 'kelola_iuran.dart';
import 'rekap_page.dart';

class AppDrawer extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Drawer(

      child: ListView(

        padding: EdgeInsets.zero,

        children: [

          // HEADER
          DrawerHeader(

            decoration: BoxDecoration(

              color:
                  Theme.of(context)
                      .primaryColor,
            ),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisAlignment:
                  MainAxisAlignment.end,

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

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // DASHBOARD
          drawerItem(
            context,
            Icons.dashboard,
            "Dashboard",
            HomeAdmin(),
          ),

          // DATA WARGA
          drawerItem(
            context,
            Icons.people,
            "Data Warga",
            DataWarga(),
          ),

          // KELOLA IURAN
          drawerItem(
            context,
            Icons.attach_money,
            "Kelola Iuran",
            KelolaIuran(),
          ),

          Divider(),

          // REKAP
          drawerItem(
            context,
            Icons.bar_chart,
            "Rekap",
            RekapPage(),
          ),

          // AGENDA
          drawerItem(
            context,
            Icons.event,
            "Agenda",
            AgendaPage(),
          ),
          
          // PENGUMUMAN
          drawerItem(
            context,
            Icons.campaign,
            "Pengumuman",
            PengumumanPage(),
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
import 'package:flutter/material.dart';
import 'package:iuran_app/pages/warga/info_warga.dart';
import 'package:iuran_app/pages/warga/iuran_saya.dart';
import 'package:iuran_app/pages/warga/pengumuman.dart';
import 'package:iuran_app/pages/warga/rekap_bulanan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iuran_app/pages/warga/detail_pengumuman.dart';
import 'package:iuran_app/services/whatsapp.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'agenda.dart';
import 'daftar_warga.dart';
import 'drawer_warga.dart';
import 'package:iuran_app/api.dart';

String nama = "";
String noRumah = "";

class HomeWarga extends StatefulWidget {
  @override
  State<HomeWarga> createState() => _HomeWargaState();
}

class _HomeWargaState extends State<HomeWarga> {
  Map user = {};
  Map pengumuman = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    getProfil();
    fetchData();
  }

  Future<void> getProfil() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getInt("id_warga");

    final response = await http.get(
      Uri.parse(
        "${Api.baseUrl}/warga/$id",
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        nama = data["nama"];
        noRumah = data["no_rumah"];
      });
    }
  }

  Future fetchData() async {
    try {
      final pengumumanRes = await http.get(
        Uri.parse(
          "${Api.baseUrl}/pengumuman-terbaru",
        ),
      );

      setState(() {
        pengumuman = jsonDecode(pengumumanRes.body);
        loading = false;
      });
    } catch (e) {
      print(e);

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text("MyMarsaid"),
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama.isEmpty
                              ? "Selamat Datang"
                              : "Selamat Datang, $nama",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "Warga Blok $noRumah",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: pengumuman.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailPengumumanWarga(
                                      pengumuman: pengumuman,
                                    ),
                                  ),
                                );
                              },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.campaign,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Pengumuman Terbaru",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Text(
                                pengumuman["judul"] ?? "Belum ada pengumuman",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pengumuman["isi"] ?? "-",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      children: [
                        // IURAN SAYA
                        menuItem(
                          context,
                          Icons.attach_money,
                          "Iuran Saya",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => IuranSaya(),
                              ),
                            );
                          },
                        ),

                        // DATA WARGA
                        menuItem(
                          context,
                          Icons.people,
                          "Data Warga",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DaftarWarga(),
                              ),
                            );
                          },
                        ),

                        // REKAP
                        menuItem(
                          context,
                          Icons.bar_chart,
                          "Rekap",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RekapBulanan(),
                              ),
                            );
                          },
                        ),

                        // PENGUMUMAN
                        menuItem(
                          context,
                          Icons.campaign,
                          "Pengumuman",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PengumumanWarga(),
                              ),
                            );
                          },
                        ),

                        // AGENDA
                        menuItem(
                          context,
                          Icons.event,
                          "Agenda",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Agenda(),
                              ),
                            );
                          },
                        ),

                        // CHAT PENGURUS
                        menuItem(
                          context,
                          Icons.chat,
                          "Chat Pengurus",
                          () {
                            WhatsappService.chatPengurus(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // =========================
  // MENU ITEM
  // =========================

  Widget menuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 42,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

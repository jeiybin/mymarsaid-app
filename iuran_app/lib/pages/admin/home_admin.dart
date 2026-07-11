import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iuran_app/api.dart';

import 'drawer_admin.dart';
import 'data_warga.dart';
import 'kelola_iuran.dart';
import 'rekap_page.dart';
import 'agenda_page.dart';
import 'pengumuman_page.dart';


import 'package:intl/intl.dart';

class HomeAdmin extends StatefulWidget {
  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  Map dashboardData = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  // FETCH DASHBOARD
  Future<void> fetchDashboard() async {
    try {
      final response = await http.get(
        Uri.parse("${Api.baseUrl}/dashboard"),
      );

      print("Dashboard Status: ${response.statusCode}");
      print("Dashboard Body: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Dashboard API Error");
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        dashboardData = data;
        isLoading = false;
      });
    } catch (e) {
      print("ERROR DASHBOARD: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // DRAWER
      drawer: AppDrawer(),

      // APPBAR
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(
                Icons.segment_rounded,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text("MyMarsaid"),
      ),

      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // HEADER
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
                          "Selamat Datang, Admin!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Kelola data warga dan iuran",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // SUMMARY CARD ROW 1
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: summaryCard(
                            Icons.people,
                            "Total Warga",
                            // PERBAIKAN DI SINI:
                            dashboardData["total_warga"]?.toString() ?? "0",
                            Colors.blue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: summaryCard(
                            Icons.warning,
                            "Belum Bayar",
                            // PERBAIKAN DI SINI:
                            dashboardData["belum_bayar"]?.toString() ?? "0",
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),

                  // SUMMARY CARD ROW 2
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: summaryCard(
                            Icons.trending_up,
                            "Terkumpul",
                            "Rp ${NumberFormat('#,###', 'id_ID').format(
                              int.tryParse(
                                    dashboardData["total_iuran"]?.toString() ??
                                        "0",
                                  ) ??
                                  0,
                            )}",
                            Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: summaryCard(
                            Icons.campaign,
                            "Pengumuman",
                            dashboardData["total_pengumuman"]?.toString() ??
                                "0",
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // MENU
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
                        // DATA WARGA
                        menuItem(
                          context,
                          Icons.people,
                          "Data Warga",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DataWarga(),
                              ),
                            );
                          },
                        ),

                        // KELOLA IURAN
                        menuItem(
                          context,
                          Icons.attach_money,
                          "Kelola Iuran",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => KelolaIuran(),
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
                                builder: (_) => RekapPage(),
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
                                  builder: (context) => AgendaPage()),
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
                                  builder: (context) => PengumumanPage()),
                            );
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

  // SUMMARY CARD
  Widget summaryCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // MENU ITEM
  Widget menuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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

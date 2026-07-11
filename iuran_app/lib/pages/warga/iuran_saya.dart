import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iuran_app/pages/warga/info_warga.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'drawer_warga.dart';
import 'detail_iuran.dart';
import 'drawer_warga.dart';




class IuranSaya extends StatefulWidget {

  const IuranSaya({super.key});

  @override
  State<IuranSaya> createState() =>
      _IuranSayaState();
}

class _IuranSayaState
    extends State<IuranSaya> {

  // =========================================
  // VARIABLE
  // =========================================
  int idWarga = 0;
  List dataIuran = [];
  bool isLoading = true;
  late int selectedYear;
  late List<int> tahunList;


  // =========================================
  // INIT
  // =========================================

  @override
  void initState() {

    super.initState();

    final now = DateTime.now();

    selectedYear = now.year;

    tahunList = [

      now.year - 1,

      now.year,

      now.year + 1,

    ];

    fetchIuran();
  }


  // =========================================
  // FETCH DATA
  // =========================================

  Future<void> fetchIuran() async {

    setState(() {

      isLoading = true;

    });

    final prefs = await SharedPreferences.getInstance();

    idWarga = prefs.getInt("id_warga") ?? 0;

    try {

      final response = await http.get(

        Uri.parse(

          "http://10.0.2.2:5000/iuran_saya/$idWarga?tahun=$selectedYear",

        ),

      );

      if (response.statusCode == 200) {

        dataIuran = jsonDecode(

          response.body,

        );

      }

    } catch (e) {

      debugPrint(

        e.toString(),

      );

    }

    setState(() {

      isLoading = false;

    });

  }


  // =========================================
  // STATUS COLOR
  // =========================================

  Color statusColor(String status) {

    switch (status) {

      case "Lunas":

        return Colors.green;

      case "Belum Bayar":

        return Colors.red;

      default:

        return Colors.orange;

    }

  }


  // =========================================
  // STATUS BG
  // =========================================

  Color statusBackground(String status) {

    switch (status) {

      case "Lunas":

        return Colors.green.shade50;

      case "Belum Bayar":

        return Colors.red.shade50;

      default:

        return Colors.orange.shade50;

    }

  }


  // =========================================
  // MONTH ICON
  // =========================================

  IconData monthIcon() {

    return Icons.calendar_month;

  }

    // =========================================
  // UI
  // =========================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Iuran Saya",
        ),
      ),
      
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )

          : Column(

              children: [

                // =========================================
                // FILTER TAHUN
                // =========================================

                Container(

                  margin: const EdgeInsets.all(16),

                  padding: const EdgeInsets.symmetric(

                    horizontal: 16,
                    vertical: 8,

                  ),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(15),

                    boxShadow: [

                      BoxShadow(

                        color: Colors.black12,

                        blurRadius: 6,

                        offset: Offset(0, 2),

                      ),

                    ],

                  ),

                  child: Row(

                    children: [

                      const Icon(

                        Icons.calendar_month,

                        color: Colors.grey,

                      ),

                      const SizedBox(width: 12),

                      const Text(

                        "Tahun",

                        style: TextStyle(

                          fontWeight: FontWeight.bold,

                          fontSize: 16,

                        ),

                      ),

                      const Spacer(),

                      DropdownButton<int>(

                        value: selectedYear,

                        underline:
                            const SizedBox(),

                        items:

                            tahunList.map(

                          (tahun) {

                            return DropdownMenuItem(

                              value: tahun,

                              child: Text(

                                tahun.toString(),

                              ),

                            );

                          },

                        ).toList(),

                        onChanged: (value) {

                          if (value == null) return;

                          setState(() {

                            selectedYear = value;

                          });

                          fetchIuran();

                        },

                      ),

                    ],

                  ),

                ),

                // =========================================
                // LIST IURAN
                // =========================================

                Expanded(

                  child: ListView.builder(

                    padding:
                        const EdgeInsets.only(

                      left: 16,
                      right: 16,
                      bottom: 20,

                    ),

                    itemCount:
                        dataIuran.length,

                    itemBuilder:

                        (context, index) {

                      final item =
                          dataIuran[index];

                      return Card(

                        elevation: 3,

                        margin:
                            const EdgeInsets.only(

                          bottom: 14,

                        ),

                        shape:
                            RoundedRectangleBorder(

                          borderRadius:
                              BorderRadius.circular(16),

                        ),

                        child: InkWell(

                          borderRadius:
                              BorderRadius.circular(16),

                          onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailIuran(
                                idRumah: item["id_rumah"],
                                bulan: item["bulan"],
                                tahun: item["tahun"],
                              ),
                            ),
                          );
                          },

                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      Theme.of(context)
                                          .primaryColor
                                          .withOpacity(.15),

                                  child: Icon(
                                    monthIcon(),
                                    color:
                                        Theme.of(context)
                                            .primaryColor,
                                  ),
                                ),

                                const SizedBox(
                                  width: 16,
                                ),

                                Expanded(

                                  child: Column(

                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        item["bulan"],
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight:
                                              FontWeight.bold,

                                        ),

                                      ),

                                      const SizedBox(
                                        height: 5,
                                      ),

                                      Text(
                                        "Klik untuk melihat detail",
                                        style: TextStyle(
                                          color:
                                              Colors.grey.shade600,

                                        ),

                                      ),

                                    ],

                                  ),

                                ),
                                                                // ===========================
                                // STATUS
                                // ===========================

                                Container(

                                  padding:
                                      const EdgeInsets.symmetric(

                                    horizontal: 12,
                                    vertical: 6,

                                  ),

                                  decoration: BoxDecoration(

                                    color: statusBackground(

                                      item["status"],

                                    ),

                                    borderRadius:
                                        BorderRadius.circular(20),

                                  ),

                                  child: Text(

                                    item["status"],

                                    style: TextStyle(

                                      color: statusColor(

                                        item["status"],

                                      ),

                                      fontWeight:
                                          FontWeight.bold,

                                    ),

                                  ),

                                ),

                                const SizedBox(width: 10),

                                const Icon(

                                  Icons.chevron_right,

                                  color: Colors.grey,

                                ),

                              ],

                            ),

                          ),

                        ),

                      );

                    },

                  ),

                ),

              ],

            ),

    );

  }

}
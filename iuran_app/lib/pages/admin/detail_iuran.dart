import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iuran_app/api.dart';

class DetailIuran extends StatefulWidget {

  final Map data;

  final String selectedMonth;

  final String selectedYear;

  DetailIuran({

    required this.data,

    required this.selectedMonth,

    required this.selectedYear,
  });

  @override
  State<DetailIuran> createState() =>
      _DetailIuranState();
}


// ==============================
// STATE
// ==============================

class _DetailIuranState
    extends State<DetailIuran> {

  Map iuran = {};

  bool isLoading = true;


  // ==============================
  // INIT
  // ==============================

  @override
  void initState() {

    super.initState();

    fetchDetailIuran();
  }


  // ==============================
  // FETCH DETAIL IURAN
  // ==============================

  Future<void> fetchDetailIuran() async {

    setState(() {
      isLoading = true;
    });

    try {

      final response = await http.get(

        Uri.parse(

          "${Api.baseUrl}/detail_iuran/"
          "${widget.data['id_rumah']}"
          "?bulan=${widget.selectedMonth}"
          "&tahun=${widget.selectedYear}",
        ),
      );

      // Di dalam fetchDetailIuran
      final data = jsonDecode(response.body);
      setState(() {
        // Pastikan iuran selalu berupa Map, tidak null
        iuran = data ?? {}; 
        isLoading = false;
      });

    } catch (e) {

      print(e);

      setState(() {
        isLoading = false;
      });
    }
  }


  // ==============================
  // EDIT IURAN DIALOG
  // ==============================

  void editIuranDialog() {
    final iuranController =
        TextEditingController(

      text:
          iuran['iuran']
              ?.toString() ??
          '0',
    );

    final kasController =
        TextEditingController(

      text:
          iuran['kas']
              ?.toString() ??
          '0',
    );

    final kasIbuController =
        TextEditingController(

      text:
          iuran['kas_ibu']
              ?.toString() ??
          '0',
    );

    final berasController =
        TextEditingController(

      text:
          iuran['beras']
              ?.toString() ??
          '0',
    );

    DateTime selectedDate =
        DateTime.now();

    showDialog(

      context: context,

      builder: (_) {

        return StatefulBuilder(

          builder:
              (context, setModalState) {

            return AlertDialog(

              title: Text(
                "Edit Pembayaran",
              ),

              content:
                  SingleChildScrollView(

                child: Column(

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    // IURAN WAJIB
                    textFieldDialog(
                      "Iuran Wajib",
                      iuranController,
                    ),

                    SizedBox(height: 14),
                    // KAS RT
                    textFieldDialog(
                      "Kas RT",
                      kasController,
                    ),

                    SizedBox(height: 14),

                    // KAS IBU
                    textFieldDialog(
                      "Kas Ibu-Ibu",
                      kasIbuController,
                    ),

                    SizedBox(height: 14),

                    // BERAS
                    textFieldDialog(
                      "Beras",
                      berasController,
                    ),

                    SizedBox(height: 18),

                    // DATE PICKER
                    ListTile(

                      contentPadding:
                          EdgeInsets.zero,

                      leading: Icon(
                        Icons.calendar_month,
                      ),

                      title: Text(

                        "${selectedDate.day}/"
                        "${selectedDate.month}/"
                        "${selectedDate.year}",
                      ),

                      onTap: () async {

                        final picked =
                            await showDatePicker(

                          context: context,

                          initialDate:
                              selectedDate,

                          firstDate:
                              DateTime(2020),

                          lastDate:
                              DateTime(2100),
                        );

                        if (picked != null) {

                          setModalState(() {

                            selectedDate =
                                picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              actions: [

                // BATAL
                TextButton(

                  onPressed: () {

                    Navigator.pop(
                        context);
                  },

                  child: Text("Batal"),
                ),

                // SIMPAN
                ElevatedButton(

                  onPressed: () async {

                    try {

                      final response =
                          await http.post(

                        Uri.parse(

                          "${Api.baseUrl}/update_iuran",
                        ),

                        headers: {

                          "Content-Type":
                              "application/json",
                        },

                        body: jsonEncode({

                          "id_rumah":

                              widget.data[
                                  'id_rumah'],

                          "bulan":

                              widget
                                  .selectedMonth,

                          "tahun":

                              int.parse(

                                widget
                                    .selectedYear,
                              ),

                          "kas":

                              int.parse(

                                kasController.text,
                              ),

                          "kas_ibu":

                              int.parse(

                                kasIbuController
                                    .text,
                              ),

                          "beras":

                              int.parse(

                                berasController
                                    .text,
                              ),

                          "tanggal_bayar":

                              "${selectedDate.year}-"

                              "${selectedDate.month.toString().padLeft(2, '0')}-"

                              "${selectedDate.day.toString().padLeft(2, '0')}",
                        }),
                      );

                      final data =
                          jsonDecode(
                              response.body);

                      Navigator.pop(
                          context);

                      fetchDetailIuran();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(

                          content: Text(
                            "Data iuran berhasil diperbarui",
                          ),
                        ),
                      );
                    } catch (e) {
                      print(e);
                    }
                  },

                  child: Text(
                    "Simpan",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // ==============================
  // UI
  // ==============================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Detail Iuran"),
      ),

      body: isLoading

          ? Center(
              child:
                  CircularProgressIndicator(),
            )

          : SingleChildScrollView(

              padding:
                  EdgeInsets.all(16),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // ==============================
                  // PROFILE CARD
                  // ==============================

                  Card(

                    child: Padding(

                      padding:
                          EdgeInsets.all(18),

                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          Text(

                            widget.data['nama'],

                            style: TextStyle(

                              fontSize: 24,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 10),

                          Text(
                            "Rumah ${widget.data['no_rumah']}",
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),


                  // ==============================
                  // FILTER INFO
                  // ==============================

                  Container(

                    width: double.infinity,

                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),

                    decoration: BoxDecoration(

                      color:
                          Theme.of(context)
                              .primaryColor
                              .withOpacity(0.12),

                      borderRadius:
                          BorderRadius.circular(
                              16),
                    ),

                    child: Row(

                      children: [

                        Icon(
                          Icons.calendar_month,
                        ),

                        SizedBox(width: 10),

                        Text(

                          "${widget.selectedMonth} ${widget.selectedYear}",

                          style: TextStyle(

                            fontWeight:
                                FontWeight.bold,

                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),


                  // ==============================
                  // DETAIL CARD
                  // ==============================

                  Card(

                    child: Padding(

                      padding:
                          EdgeInsets.all(18),

                      child: Column(

                        children: [
                          detailItem(
                            "Iuran Wajib",
                            formatRupiah(iuran['iuran'] ?? 0),
                          ),
                          detailItem(
                            "Kas RT",
                            formatRupiah(iuran['kas'] ?? 0), // Tambahkan ?? 0
                          ),
                          detailItem(
                            "Kas Ibu-Ibu",
                            formatRupiah(iuran['kas_ibu'] ?? 0), // Tambahkan ?? 0
                          ),
                          detailItem(
                            "Beras",
                            formatRupiah(iuran['beras'] ?? 0), // Tambahkan ?? 0
                          ),

                          Divider(),

                          detailItem(
                            "Total",
                            formatRupiah(
                              iuran['total'],
                            ),
                          ),

                          Divider(),

                          detailItem(
                            "Tanggal Pembayaran",
                            iuran['tanggal_bayar'] ?? "-",
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),


                  // ==============================
                  // BUTTON EDIT
                  // ==============================

                  SizedBox(

                    width: double.infinity,

                    child:
                        ElevatedButton.icon(

                      onPressed: () {

                        editIuranDialog();
                      },

                      icon: Icon(
                        Icons.edit,
                      ),

                      label: Text(
                        "Edit Pembayaran",
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }


  // ==============================
  // DETAIL ITEM
  // ==============================

  Widget detailItem(
    String title,
    String value,
  ) {

    return Padding(

      padding:
          EdgeInsets.only(bottom: 16),

      child: Row(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Expanded(

            flex: 2,

            child: Text(

              title,

              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          SizedBox(width: 12),

          Expanded(

            flex: 3,

            child: Text(

              value,

              textAlign:
                  TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }


  // ==============================
  // FORMAT TANGGAL
  // ==============================

  String formatTanggal(
    String tanggal,
  ) {

    if (tanggal == '-') {
      return '-';
    }

    try {

      DateTime parsed =
          DateTime.parse(
        tanggal,
      );

      return

        "${parsed.day}/"
        "${parsed.month}/"
        "${parsed.year}";

    } catch (e) {

      return tanggal;
    }
  }

// ==============================
// FORMAT RUPIAH
// ==============================

String formatRupiah(dynamic nominal) {
  if (nominal == null || nominal.toString() == "null") {
    return "Rp 0";
  }
  
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  return formatter.format(int.tryParse(nominal.toString()) ?? 0);
}

  // ==============================
  // TEXTFIELD DIALOG
  // ==============================

  Widget textFieldDialog(

    String label,

    TextEditingController controller,
  ) {

    return TextField(

      controller: controller,

      keyboardType:
          TextInputType.number,

      decoration: InputDecoration(
        labelText: label,
        prefixText: "Rp ",
      ),
    );
  }
}
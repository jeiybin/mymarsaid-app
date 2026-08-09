import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iuran_app/api.dart';

class DetailIuran extends StatefulWidget {
  final int idRumah;
  final String bulan;
  final int tahun;

  const DetailIuran({
    super.key,
    required this.idRumah,
    required this.bulan,
    required this.tahun,
  });

  @override
  State<DetailIuran> createState() => _DetailIuranState();
}

class _DetailIuranState extends State<DetailIuran> {
  Map data = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/detail_iuran/${widget.idRumah}?bulan=${widget.bulan}&tahun=${widget.tahun}",
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          data = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      loading = false;
    });
  }

  Color statusColor() {
    return data["status"] == "Lunas" ? Colors.green : Colors.red;
  }

  IconData statusIcon() {
    return data["status"] == "Lunas" ? Icons.check_circle : Icons.cancel;
  }

  String rupiah(dynamic angka) {
    final format = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    );

    return format.format(
      double.tryParse(
            angka.toString(),
          ) ??
          0,
    );
  }

  String tanggalBayar() {
    if (data["tanggal_bayar"] == null) {
      return "-";
    }

    try {
      return DateFormat(
        "dd MMMM yyyy",
        "id_ID",
      ).format(
        DateTime.parse(
          data["tanggal_bayar"],
        ),
      );
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Iuran"),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${data["bulan"]} ${data["tahun"]}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                statusIcon(),
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                data["status"],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Rincian Iuran",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 30),
                          buildItem(
                            "Iuran Wajib",
                            rupiah(data["iuran"]),
                          ),
                          buildItem(
                            "Kas",
                            rupiah(data["kas"]),
                          ),
                          buildItem(
                            "Kas Ibu",
                            rupiah(data["kas_ibu"]),
                          ),
                          buildItem(
                            "Beras",
                            rupiah(data["beras"]),
                          ),
                          const Divider(height: 30),
                          buildItem(
                            "Total",
                            rupiah(data["total"]),
                            bold: true,
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 30),
                          buildItem(
                            "Tanggal Bayar",
                            tanggalBayar(),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildItem(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

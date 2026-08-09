import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iuran_app/api.dart';

class RekapPengeluaran extends StatefulWidget {
  final String bulan;
  final String tahun;

  const RekapPengeluaran({
    super.key,
    required this.bulan,
    required this.tahun,
  });

  @override
  State<RekapPengeluaran> createState() => _RekapPengeluaranState();
}

class _RekapPengeluaranState extends State<RekapPengeluaran> {
  List pengeluaranList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetailPengeluaran();
  }

  Future<void> fetchDetailPengeluaran() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/detail_pengeluaran?bulan=${widget.bulan}&tahun=${widget.tahun}",
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          pengeluaranList = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("ERROR PENGELUARAN : $e");
      setState(() => isLoading = false);
    }
  }

  String formatRupiah(dynamic nominal) {
    return NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    ).format(int.tryParse(nominal.toString()) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Pengeluaran"),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : pengeluaranList.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada pengeluaran.",
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pengeluaranList.length,
                  itemBuilder: (context, index) {
                    final item = pengeluaranList[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["keterangan"] ?? "-",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item["tanggal"] ?? "-",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              formatRupiah(item["nominal"]),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class RekapPemasukan extends StatefulWidget {
  final String bulan;
  final String tahun;

  const RekapPemasukan({
    super.key,
    required this.bulan,
    required this.tahun,
  });

  @override
  State<RekapPemasukan> createState() => _RekapPemasukanState();
}

class _RekapPemasukanState extends State<RekapPemasukan> {
  List pemasukanList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetailPemasukan();
  }

  Future<void> fetchDetailPemasukan() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          "http://10.0.2.2:5000/detail_pemasukan?bulan=${widget.bulan}&tahun=${widget.tahun}",
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          pemasukanList = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("ERROR PEMASUKAN: $e");
      setState(() => isLoading = false);
    }
  }

  String formatRupiah(dynamic nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(int.tryParse(nominal.toString()) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rekap Pemasukan"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pemasukanList.isEmpty
              ? const Center(
                  child: Text("Belum ada pemasukan."),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pemasukanList.length,
                  itemBuilder: (context, index) {
                    final item = pemasukanList[index];

                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["jenis"] ?? "-",
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
                                color: Colors.green,
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

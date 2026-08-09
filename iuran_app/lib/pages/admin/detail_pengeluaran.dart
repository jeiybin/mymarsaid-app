import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iuran_app/api.dart';
import 'aksi_pengeluaran.dart';

class DetailPengeluaranPage extends StatefulWidget {
  final String bulan;
  final String tahun;

  DetailPengeluaranPage({
    required this.bulan,
    required this.tahun,
  });

  @override
  State<DetailPengeluaranPage> createState() => _DetailPengeluaranPageState();
}

class _DetailPengeluaranPageState extends State<DetailPengeluaranPage> {
  List pengeluaranList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetailPengeluaran();
  }

  // FETCH DATA
  Future<void> fetchDetailPengeluaran() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/detail_pengeluaran?bulan=${widget.bulan}&tahun=${widget.tahun}",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          pengeluaranList = data;
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  void dialogTambahPengeluaran() {
    final jenisController = TextEditingController();
    final nominalController = TextEditingController();
    final keteranganController = TextEditingController();

    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text("Tambah Pengeluaran"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    textField(
                      "Jenis",
                      jenisController,
                    ),
                    textField(
                      "Nominal",
                      nominalController,
                    ),
                    textField(
                      "Keterangan",
                      keteranganController,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_month,
                      ),
                      title: Text(
                        DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(
                          selectedDate,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setModalState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await http.post(
                      Uri.parse(
                        "${Api.baseUrl}/add_pengeluaran",
                      ),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "jenis": jenisController.text,
                        "tanggal": DateFormat(
                          'yyyy-MM-dd',
                        ).format(
                          selectedDate,
                        ),
                        "nominal": nominalController.text,
                        "keterangan": keteranganController.text,
                      }),
                    );
                    Navigator.pop(context);

                    fetchDetailPengeluaran();
                  },
                  child: Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // FORMAT RUPIAH
  String formatRupiah(dynamic nominal) {
    if (nominal == null) return "Rp 0";
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(int.tryParse(nominal.toString()) ?? 0);
  }

  // WIDGET TEXTFIELD KONSISTEN
  Widget textField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daftar Pengeluaran"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pengeluaranList.isEmpty
              ? const Center(
                  child: Text("Belum ada pengeluaran."),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: pengeluaranList.length,
                  itemBuilder: (context, index) {
                    final item = pengeluaranList[index];

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AksiPengeluaranPage(
                                item: item,
                                refreshParent: () => fetchDetailPengeluaran(),
                              ),
                            ),
                          );
                        },
                        title: Text(
                          item['jenis'] ?? '-',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['keterangan'] ?? '',
                            ),
                            SizedBox(height: 4),
                            Text(
                              item['tanggal'] ?? '-',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          formatRupiah(
                            item['nominal'],
                          ),
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: dialogTambahPengeluaran,
        child: Icon(Icons.add),
      ),
    );
  }
}

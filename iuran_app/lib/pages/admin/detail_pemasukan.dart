import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iuran_app/api.dart';
import 'aksi_pemasukan.dart';

class DetailPemasukanPage extends StatefulWidget {
  final String bulan;
  final String tahun;

  DetailPemasukanPage({
    required this.bulan,
    required this.tahun,
  });

  @override
  State<DetailPemasukanPage> createState() => _DetailPemasukanPageState();
}

class _DetailPemasukanPageState extends State<DetailPemasukanPage> {
  List pemasukanList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetailPemasukan();
  }

  // FETCH DATA
  Future<void> fetchDetailPemasukan() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/detail_pemasukan?bulan=${widget.bulan}&tahun=${widget.tahun}",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          pemasukanList = data;
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

  // DIALOG TAMBAH DATA
  void dialogTambahPemasukan() {
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
              title: Text("Tambah Pemasukan"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: jenisController,
                      decoration: InputDecoration(labelText: "Jenis Pemasukan"),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: nominalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Nominal"),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: keteranganController,
                      decoration: InputDecoration(labelText: "Keterangan"),
                    ),
                    SizedBox(height: 18),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_month,),
                      title: Text(
                        DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(
                          selectedDate,
                        ),
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await http.post(
                        Uri.parse("${Api.baseUrl}/add_pemasukan"),
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({
                          "tanggal": DateFormat('yyyy-MM-dd').format(selectedDate),
                          "jenis": jenisController.text,
                          "nominal": nominalController.text,
                          "keterangan": keteranganController.text,
                        }),
                      );
                      Navigator.pop(context);
                      fetchDetailPemasukan();
                    } catch (e) {
                      print(e);
                    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daftar Pemasukan"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pemasukanList.isEmpty
              ? const Center(
                  child: Text("Belum ada pemasukan."),
                )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: pemasukanList.length,
              itemBuilder: (context, index) {
                final item = pemasukanList[index];

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () {
                      if (item['id'] != 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AksiPemasukanPage(
                              item: item,
                              refreshParent: () => fetchDetailPemasukan(),
                            ),
                          ),
                        );
                      }
                    },
                    title: Text(
                      item['jenis'] ?? '-',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(item['tanggal'] ?? '-'),
                    trailing: Text(
                      formatRupiah(item['nominal']),
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: dialogTambahPemasukan,
        child: Icon(Icons.add),
      ),
    );
  }
}
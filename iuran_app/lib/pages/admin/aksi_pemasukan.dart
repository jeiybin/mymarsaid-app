import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:iuran_app/api.dart';

class AksiPemasukanPage extends StatefulWidget {
  final Map item;
  final Function refreshParent;

  AksiPemasukanPage({required this.item, required this.refreshParent});

  @override
  State<AksiPemasukanPage> createState() => _AksiPemasukanPageState();
}

class _AksiPemasukanPageState extends State<AksiPemasukanPage> {
  void dialogFormPemasukan(Map data) {
    final jenisController = TextEditingController(text: data['jenis']);
    final nominalController = TextEditingController(text: data['nominal'].toString());
    final keteranganController = TextEditingController(text: data['keterangan']);
    DateTime selectedDate = DateTime.parse(data['tanggal']);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text("Edit Pemasukan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: jenisController, decoration: InputDecoration(labelText: "Jenis")),
                SizedBox(height: 14),
                TextField(controller: nominalController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Nominal", prefixText: "Rp ")),
                SizedBox(height: 14),
                TextField(controller: keteranganController, decoration: InputDecoration(labelText: "Keterangan")),
                SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_month),
                  title: Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (picked != null) setModalState(() => selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await http.post(
                  Uri.parse("${Api.baseUrl}/edit_pemasukan/${data['id']}"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "tanggal": "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                    "jenis": jenisController.text,
                    "nominal": nominalController.text,
                    "keterangan": keteranganController.text,
                  }),
                );
                widget.refreshParent();
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  String formatRupiah(dynamic nominal) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(int.tryParse(nominal.toString()) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Pemasukan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // CARD UTAMA
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.label_outline, "Jenis", widget.item['jenis'] ?? '-'),
                    _buildInfoRow(Icons.description_outlined, "Keterangan", widget.item['keterangan'] ?? '-'),
                    _buildInfoRow(Icons.calendar_today, "Tanggal", widget.item['tanggal'] ?? '-'),
                    
                    const Divider(height: 30, thickness: 1),
                    
                    //Nominal
                    const Text("Nominal", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      formatRupiah(widget.item['nominal']),
                      style: const TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.green 
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // TOMBOL AKSI
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Edit Data"),
              onPressed: () => dialogFormPemasukan(widget.item),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text("Hapus Data", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                bool confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Konfirmasi"),
                    content: Text("Yakin ingin menghapus data ini?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Batal")),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Hapus")),
                    ],
                  ),
                );
                if (confirm == true) {
                  await http.delete(Uri.parse("${Api.baseUrl}/hapus_pemasukan/${widget.item['id']}"));
                  widget.refreshParent();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, 
                minimumSize: const Size(double.infinity, 55)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          const Text(": "),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
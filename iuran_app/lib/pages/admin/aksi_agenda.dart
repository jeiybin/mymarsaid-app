import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iuran_app/pages/admin/detail_agenda.dart';
import 'detail_agenda.dart';
import 'package:iuran_app/api.dart';

class AksiAgendaPage extends StatefulWidget {
  final Map agenda;
  final Function refreshParent;

  AksiAgendaPage({required this.agenda, required this.refreshParent});

  @override
  State<AksiAgendaPage> createState() => _AksiAgendaPageState();
}

class _AksiAgendaPageState extends State<AksiAgendaPage> {
  late Map currentAgenda;

  @override
  void initState() {
    super.initState();
    currentAgenda = widget.agenda;
  }

  String formatRupiah(dynamic nominal) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(int.tryParse(nominal.toString()) ?? 0);
  }

  void tampilkanFormEdit() {
    final nominalController =
        TextEditingController(text: currentAgenda['nominal'].toString());
    final ketController = TextEditingController(text: currentAgenda['ket']);

    DateTime selectedDate =
        DateTime.parse(
          currentAgenda['tgl'].toString(),
        );

    final tglController =
        TextEditingController(
          text: DateFormat(
            'yyyy-MM-dd',
          ).format(
            selectedDate,
          ),
        );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Transaksi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nominalController,
                decoration: const InputDecoration(labelText: "Nominal")),
              TextField(
                  controller: tglController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Tanggal",
                    suffixIcon:
                        Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? picked =
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
                      selectedDate =
                          picked;

                      tglController.text =
                          DateFormat(
                        'yyyy-MM-dd',
                      ).format(
                        picked,
                      );
                    }
                  },
                ),
            TextField(
                controller: ketController,
                decoration: const InputDecoration(labelText: "Keterangan")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final id = currentAgenda['id_transaksi']?.toString() ??
                  currentAgenda['id']?.toString() ??
                  '';

              final response = await http.post(
                  Uri.parse("${Api.baseUrl}/edit_transaksi"),
                  body: {
                    'id': id,
                    'nominal': nominalController.text
                        .replaceAll('.', '')
                        .replaceAll(',', ''),
                    'ket': ketController.text,
                    'kategori': currentAgenda['kategori'] ?? '',
                    'tgl': tglController.text,
                  });

              if (response.statusCode == 200) {
                setState(() {
                  currentAgenda['nominal'] = nominalController.text;
                  currentAgenda['ket'] = ketController.text;
                });

                widget.refreshParent(); 

                Navigator.pop(context);
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Berhasil diupdate!")));
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Transaksi")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentAgenda['nama_warga'] != null) ...[
                      Text(currentAgenda['nama_warga'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                    ],
                    
                    Text(currentAgenda['kategori'] ?? '-', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    
                    const Divider(height: 30, thickness: 1),
                    
                    _buildInfoRow(
                      Icons.calendar_today,
                      "Tanggal",
                      currentAgenda['tgl'] != null
                          ? DateFormat(
                              'dd MMMM yyyy',
                              'id_ID',
                            ).format(
                              DateTime.parse(
                                currentAgenda['tgl'].toString(),
                              ),
                            )
                          : "-",
                    ),
                    
                    _buildInfoRow(Icons.description_outlined, "Keterangan", currentAgenda['ket'] ?? '-'),
                    
                    const SizedBox(height: 20),
                    
                    const Text("Nominal", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      formatRupiah(currentAgenda['nominal']),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // TOMBOL EDIT
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Edit Data"),
              onPressed: tampilkanFormEdit,
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55)),
            ),
            const SizedBox(height: 15),

            // TOMBOL HAPUS
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text("Hapus Data",
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final id = currentAgenda['id_transaksi']?.toString() ??
                    currentAgenda['id']?.toString() ??
                    '';
                bool confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                                title: const Text("Konfirmasi"),
                                content: const Text(
                                    "Yakin ingin menghapus data ini?"),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Batal")),
                                  ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Hapus")),
                                ])) ??
                    false;

                if (confirm) {
                  await http.delete(
                      Uri.parse("${Api.baseUrl}/hapus_transaksi/$id"));
                  widget.refreshParent();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 55)),
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
          SizedBox(
              width: 100,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          const Text(": "),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

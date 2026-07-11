import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'detail_pengumuman.dart';

class PengumumanPage extends StatefulWidget {
  @override
  State<PengumumanPage> createState() => _PengumumanPageState();
}

class _PengumumanPageState extends State<PengumumanPage> {
  List pengumumanList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPengumuman();
  }

  Future<void> fetchPengumuman() async {
    setState(() => isLoading = true);
    try {
      final response =
          await http.get(Uri.parse("http://10.0.2.2:5000/pengumuman"));
      if (response.statusCode == 200) {
        setState(() {
          pengumumanList = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengumuman Warga")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pengumumanList.isEmpty
              ? const Center(child: Text("Belum ada pengumuman"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pengumumanList.length,
                  itemBuilder: (context, i) {
                    final item = pengumumanList[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPengumuman(
                                pengumuman: item,
                                refreshParent: fetchPengumuman,
                              ),
                            ),
                          );
                        },
                        leading:
                            const CircleAvatar(child: Icon(Icons.campaign)),
                        title: Text(item['judul'] ?? '-',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Builder(builder: (context) {
                              String rawDate = item['tgl'] ?? '';
                              String displayDate;

                              try {
                                // Membersihkan string dari sisa data "GMT" atau format lama
                                String cleanDate = rawDate
                                    .replaceAll(' GMT', '')
                                    .replaceAll('Sat, ', '');
                                DateTime parsedDate = DateTime.parse(cleanDate);

                                // Format cantik dengan zona waktu WIB
                                displayDate =
                                    DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(parsedDate) +' WIB';
                              } catch (e) {
                                // Jika gagal parse, bersihkan paksa dari teks GMT agar tidak tampil
                                displayDate = rawDate.replaceAll(' GMT', '');
                              }

                              return Text(displayDate,
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey));
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialogTambahPengumuman(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void showDialogTambahPengumuman() {
    final judulController = TextEditingController();
    final isiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Pengumuman"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: judulController,
                decoration: const InputDecoration(labelText: "Judul")),
            TextField(
                controller: isiController,
                decoration: const InputDecoration(labelText: "Isi Pengumuman"),
                maxLines: 5),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse("http://10.0.2.2:5000/add_pengumuman");

              // Mengirim format tanggal yang bersih sejak awal
              String formattedTgl =
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

              await http.post(url, body: {
                'judul': judulController.text,
                'isi': isiController.text,
                'tgl': formattedTgl,
              });

              Navigator.pop(context);
              fetchPengumuman();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}

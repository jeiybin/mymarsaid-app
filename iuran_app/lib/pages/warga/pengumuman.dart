import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'detail_pengumuman.dart';

class PengumumanWarga extends StatefulWidget {
  const PengumumanWarga({super.key});

  @override
  State<PengumumanWarga> createState() => _PengumumanWargaState();
}

class _PengumumanWargaState extends State<PengumumanWarga> {
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
      final response = await http.get(Uri.parse("http://10.0.2.2:5000/pengumuman"));
      if (response.statusCode == 200) {
        setState(() {
          pengumumanList = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengumuman")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pengumumanList.isEmpty
              ? const Center(child: Text("Belum ada pengumuman"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pengumumanList.length,
                  itemBuilder: (context, i) {
                    final item = pengumumanList[i];
                    String tanggal = item["tgl"] ?? "-";
                    try {
                      tanggal = DateFormat("dd MMMM yyyy, HH:mm", "id_ID")
                              .format(DateTime.parse(tanggal)) +
                          " WIB";
                    } catch (_) {}
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPengumumanWarga(pengumuman: item),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.blue.withOpacity(.15),
                                child: const Icon(Icons.campaign,color: Colors.blue),
                              ),
                              const SizedBox(width:16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item["judul"]??"-",style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height:6),
                                    Text(tanggal,style: TextStyle(color: Colors.grey.shade600,fontSize:12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
    );
  }
}

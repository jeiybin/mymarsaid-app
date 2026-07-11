import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iuran_app/api.dart';
import 'edit_pengumuman.dart';

class DetailPengumuman extends StatefulWidget {
  final Map pengumuman;
  final Function refreshParent;

  const DetailPengumuman({
    super.key,
    required this.pengumuman,
    required this.refreshParent,
  });

  @override
  State<DetailPengumuman> createState() =>
      _DetailPengumumanState();
}

class _DetailPengumumanState extends State<DetailPengumuman> {

  late Map currentData;

  @override
  void initState() {
    super.initState();
    currentData = widget.pengumuman;
  }

  Future<void> fetchDetailPengumuman() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/pengumuman/${currentData['id']}",
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          currentData = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> hapusPengumuman() async {

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: Text(
          "Yakin ingin menghapus pengumuman \"${currentData['judul']}\" ?",
        ),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Batal"),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Hapus",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),

        ],
      ),
    );

    if (confirm != true) return;

    try {

      final response = await http.delete(

        Uri.parse(
          "${Api.baseUrl}/hapus_pengumuman/${currentData['id']}",
        ),

      );

      if (response.statusCode == 200) {

        widget.refreshParent();

        if (!mounted) return;

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Pengumuman berhasil dihapus",
            ),
          ),
        );

      } else {

        throw Exception("Gagal menghapus");

      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Terjadi kesalahan saat menghapus",
          ),
        ),
      );

    }

  }

  String formatTanggal() {

    try {

      return DateFormat(
        "dd MMMM yyyy, HH:mm",
        "id_ID",
      ).format(
        DateTime.parse(currentData["tgl"]),
      ) + " WIB";

    } catch (e) {

      return currentData["tgl"] ?? "-";

    }

  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [

              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text("Edit"),
                  onPressed: () async {

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPengumuman(
                          pengumuman: currentData,
                        ),
                      ),
                    );

                    if (result == true) {
                      await fetchDetailPengumuman();
                      widget.refreshParent();
                    }

                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text("Hapus",
                  style: TextStyle(color: Colors.white)),
                  onPressed: hapusPengumuman,
                ),
              ),
            ],
          ),
        ),
      ),

      appBar: AppBar(
        title: const Text("Detail Pengumuman"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(
                  Icons.campaign,
                  size: 45,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              currentData["judul"] ?? "-",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              formatTanggal(),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 24),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          color: Colors.blueGrey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Isi Pengumuman",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 25),

                    Text(
                      currentData["isi"] ?? "-",
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
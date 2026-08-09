import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iuran_app/api.dart';

class TambahPengumumanPage extends StatefulWidget {
  const TambahPengumumanPage({super.key});

  @override
  State<TambahPengumumanPage> createState() =>
      _TambahPengumumanPageState();
}

class _TambahPengumumanPageState
    extends State<TambahPengumumanPage> {

  final judulController = TextEditingController();
  final isiController = TextEditingController();

  bool isLoading = false;

  Future<void> simpanPengumuman() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
        "${Api.baseUrl}/add_pengumuman",
      );

      String formattedTgl =
          DateFormat('yyyy-MM-dd HH:mm:ss')
              .format(DateTime.now());

      final response = await http.post(
        url,
        body: {
          'judul': judulController.text,
          'isi': isiController.text,
          'tgl': formattedTgl,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menyimpan pengumuman"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terjadi kesalahan"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    judulController.dispose();
    isiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Pengumuman"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: judulController,
              decoration: const InputDecoration(
                labelText: "Judul",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: isiController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: "Isi Pengumuman",
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : simpanPengumuman,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Simpan"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iuran_app/api.dart';
class EditPengumuman extends StatefulWidget {

  final Map pengumuman;

  const EditPengumuman({
    super.key,
    required this.pengumuman,
  });

  @override
  State<EditPengumuman> createState() =>
      _EditPengumumanPageState();
}

class _EditPengumumanPageState
    extends State<EditPengumuman> {

  late TextEditingController judulController;
  late TextEditingController isiController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    judulController = TextEditingController(
      text: widget.pengumuman["judul"],
    );

    isiController = TextEditingController(
      text: widget.pengumuman["isi"],
    );
  }

  @override
  void dispose() {

    judulController.dispose();
    isiController.dispose();

    super.dispose();
  }

  Future<void> updatePengumuman() async {

    if (judulController.text.trim().isEmpty ||
        isiController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Semua field harus diisi.",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final response = await http.put(

        Uri.parse(
          "${Api.baseUrl}/edit_pengumuman/${widget.pengumuman["id"]}",
        ),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({

          "judul": judulController.text,

          "isi": isiController.text,

        }),

      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          result["status"] == "success") {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(
            content: Text(
              "Pengumuman berhasil diperbarui.",
            ),
          ),

        );

        Navigator.pop(context, true);

      } else {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
            content: Text(
              result["message"],
            ),
          ),

        );

      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),

      );

    }

    if (mounted) {

      setState(() {
        isLoading = false;
      });

    }

  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Pengumuman"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: judulController,
              decoration: InputDecoration(
                labelText: "Judul Pengumuman",
                prefixIcon: const Icon(Icons.campaign),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: isiController,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: "Isi Pengumuman",
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 150),
                  child: Icon(Icons.description),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(

                onPressed:
                    isLoading
                        ? null
                        : updatePengumuman,

                icon: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),

                label: Text(
                  isLoading
                      ? "Menyimpan..."
                      : "Simpan Perubahan",
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
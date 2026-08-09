import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'drawer_admin.dart';
import 'package:iuran_app/api.dart';

class TambahWarga extends StatefulWidget {
  @override
  State<TambahWarga> createState() => _TambahWargaState();
}

class _TambahWargaState extends State<TambahWarga> {
  final namaController = TextEditingController();

  final hpController = TextEditingController();

  final rumahController = TextEditingController();

  final tanahController = TextEditingController();

  String selectedStatus = "aktif";

  bool isLoading = false;

  // TAMBAH WARGA
  Future<void> tambahWarga() async {
    // Validasi field kosong
    if (namaController.text.trim().isEmpty ||
        hpController.text.trim().isEmpty ||
        rumahController.text.trim().isEmpty ||
        tanahController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua data wajib diisi"),
        ),
      );
      return;
    }

    // Validasi No HP
    if (!RegExp(r'^[0-9]+$').hasMatch(hpController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nomor HP hanya boleh berisi angka"),
        ),
      );
      return;
    }

    // Validasi Luas Tanah
    final int? luasTanah = int.tryParse(tanahController.text.trim());

    if (luasTanah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Luas tanah harus berupa angka"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/add_warga"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nama": namaController.text.trim(),
          "no_hp": hpController.text.trim(),
          "no_rumah": rumahController.text.trim(),
          "luas_tanah": luasTanah,
          "status": selectedStatus,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        isLoading = false;
      });

      if (data["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Warga berhasil ditambahkan"),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ?? "Gagal tambah warga",
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak bisa konek ke server"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tambah Warga"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            textField(
              "Nama Lengkap",
              namaController,
            ),

            SizedBox(height: 16),

            textField(
              "Nomor Rumah",
              rumahController,
            ),

            SizedBox(height: 16),

            textField(
              "Nomor HP",
              hpController,
            ),

            SizedBox(height: 16),

            textField(
              "Luas Tanah",
              tanahController,
            ),

            SizedBox(height: 16),

            DropdownButtonFormField(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: "Status",
              ),
              items: [
                DropdownMenuItem(
                  value: "aktif",
                  child: Text("Aktif"),
                ),
                DropdownMenuItem(
                  value: "nonaktif",
                  child: Text("Nonaktif"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
              },
            ),

            SizedBox(height: 30),

            // button simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : tambahWarga,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Tambah Warga",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TEXTFIELD
  Widget textField(
    String label,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}

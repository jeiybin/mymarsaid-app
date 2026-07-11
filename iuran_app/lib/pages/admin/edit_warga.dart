import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'drawer_admin.dart';

class EditWarga extends StatefulWidget {
  final Map data;
  final Function refreshParent;

  EditWarga({required this.data, required this.refreshParent});

  @override
  State<EditWarga> createState() => _EditWargaState();
}

class _EditWargaState extends State<EditWarga> {
  late TextEditingController nama;

  late TextEditingController hp;

  late TextEditingController rumah;

  late TextEditingController tanah;

  String status = "aktif";

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    nama = TextEditingController(text: widget.data['nama']);
    hp = TextEditingController(text: widget.data['no_hp']);
    rumah = TextEditingController(text: widget.data['no_rumah']);
    tanah = TextEditingController(text: widget.data['luas_tanah'].toString());

    String rawStatus =
        (widget.data['status'] ?? 'aktif').toString().toLowerCase();
    status =
        (rawStatus == 'aktif' || rawStatus == 'nonaktif') ? rawStatus : 'aktif';
  }

  // UPDATE WARGA
  Future<void> updateWarga() async {
    setState(() {
      isLoading = true;
    });

  try {
        final response = await http.put(
          Uri.parse("http://10.0.2.2:5000/edit_warga/${widget.data['id_warga']}"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "nama": nama.text,
            "no_hp": hp.text,
            "no_rumah": rumah.text,
            "luas_tanah": int.parse(tanah.text),
            "status": status,
          }),
        );

        setState(() {
          isLoading = false;
        });

        // PERBAIKAN: Cukup cek apakah status code-nya 200 (Berhasil)
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Berhasil diupdate")),
          );
          
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal update: ${response.statusCode}")),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print(e);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Warga"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // NAMA
            textField(
              "Nama",
              nama,
            ),

            SizedBox(height: 16),

            // NO RUMAH
            textField(
              "No Rumah",
              rumah,
            ),

            SizedBox(height: 16),

            // NO HP
            textField(
              "No HP",
              hp,
            ),

            SizedBox(height: 16),

            // LUAS TANAH
            textField(
              "Luas Tanah",
              tanah,
            ),

            SizedBox(height: 16),

            // STATUS
            DropdownButtonFormField<String>(
              // Tambahkan <String>
              value: status,
              decoration: InputDecoration(labelText: "Status"),
              items: [
                DropdownMenuItem(value: "aktif", child: Text("Aktif")),
                DropdownMenuItem(value: "nonaktif", child: Text("Nonaktif")),
              ],
              onChanged: (value) {
                setState(() {
                  status = value!;
                });
              },
            ),

            SizedBox(height: 30),

            // BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateWarga,
                style: ElevatedButton.styleFrom(
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
                        "Update",
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

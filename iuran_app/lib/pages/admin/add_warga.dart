import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'drawer_admin.dart';

class TambahWarga extends StatefulWidget {

  @override
  State<TambahWarga> createState() =>
      _TambahWargaState();
}

class _TambahWargaState
    extends State<TambahWarga> {

  final namaController =
      TextEditingController();

  final hpController =
      TextEditingController();

  final rumahController =
      TextEditingController();

  final tanahController =
      TextEditingController();

  String selectedStatus = "aktif";

  bool isLoading = false;

  // TAMBAH WARGA
  Future<void> tambahWarga() async {

    setState(() {
      isLoading = true;
    });

    try {

      final response = await http.post(

        Uri.parse(
          "http://10.0.2.2:5000/add_warga",
        ),

        headers: {

          "Content-Type":
              "application/json",
        },

        body: jsonEncode({

          "nama":
              namaController.text,

          "no_hp":
              hpController.text,

          "no_rumah":
              rumahController.text,

          "luas_tanah":
              int.parse(
                tanahController.text,
              ),

          "status":
              selectedStatus,
        }),
      );

      final data =
          jsonDecode(response.body);

      setState(() {
        isLoading = false;
      });

      if (data["status"] ==
          "success") {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(

            content: Text(
              "Warga berhasil ditambahkan",
            ),
          ),
        );

        Navigator.pop(context, true);

      } else {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(
            content:
                Text("Gagal tambah warga"),
          ),
        );
      }

    } catch (e) {

      setState(() {
        isLoading = false;
      });

      print(e);

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content:
              Text("Tidak bisa konek server"),
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

            // NAMA
            textField(
              "Nama Lengkap",
              namaController,
            ),

            SizedBox(height: 16),

            // NO RUMAH
            textField(
              "Nomor Rumah",
              rumahController,
            ),

            SizedBox(height: 16),

            // NO HP
            textField(
              "Nomor HP",
              hpController,
            ),

            SizedBox(height: 16),

            // LUAS TANAH
            textField(
              "Luas Tanah",
              tanahController,
            ),

            SizedBox(height: 16),

            // STATUS
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

            // BUTTON
            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed:
                    isLoading
                        ? null
                        : tambahWarga,

                style:
                    ElevatedButton.styleFrom(

                  padding:
                      EdgeInsets.symmetric(
                    vertical: 16,
                  ),

                  shape:
                      RoundedRectangleBorder(

                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),
                ),

                child: isLoading

                    ? SizedBox(

                        height: 20,
                        width: 20,

                        child:
                            CircularProgressIndicator(

                          color:
                              Colors.white,

                          strokeWidth: 2,
                        ),
                      )

                    : Text(

                        "Tambah Warga",

                        style: TextStyle(

                          fontSize: 16,

                          fontWeight:
                              FontWeight.w600,
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
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iuran_app/api.dart';
import 'home_warga.dart';

class ProfilWarga extends StatefulWidget {
  const ProfilWarga({super.key});

  @override
 State<ProfilWarga> createState() => ProfilSaya();
}

class ProfilSaya extends State<ProfilWarga> {
  bool loading = true;
  bool saving = false;

  int? idWarga;

  Map<String, dynamic> profil = {};

  final TextEditingController namaController = TextEditingController();
  final TextEditingController hpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getProfil();
  }

  Future<void> getProfil() async {
    final prefs = await SharedPreferences.getInstance();

    idWarga = prefs.getInt("id_warga");

    if (idWarga == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/warga/$idWarga",
        ),
      );

      if (response.statusCode == 200) {
        profil = jsonDecode(response.body);

        namaController.text = profil["nama"] ?? "";
        hpController.text = profil["no_hp"] ?? "";

        setState(() {
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      print(e);

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> simpanProfil() async {
    if (idWarga == null) return;

    setState(() {
      saving = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
          "${Api.baseUrl}/edit_profil_warga/$idWarga",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nama": namaController.text,
          "no_hp": hpController.text,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data["message"]),
        ),
      );

      getProfil();
    } catch (e) {
      print(e);

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal memperbarui profil"),
        ),
      );
    }
  }

  Future<void> showEditDialog({
    required String title,
    required TextEditingController controller,
  }) async {
    final tempController = TextEditingController(
      text: controller.text,
    );

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(title),
          content: TextField(
            controller: tempController,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                controller.text = tempController.text;

                Navigator.pop(context);

                await simpanProfil();
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  Widget infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HomeWarga(),
              ),
            );
          },
        ),
        title: const Text("Profil Saya"),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    profil["nama"] ?? "-",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text("Nama"),
                          subtitle: Text(
                            namaController.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              showEditDialog(
                                title: "Edit Nama",
                                controller: namaController,
                              );
                            },
                          ),
                        ),

                        const Divider(height: 1),

                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: const Text("Nomor Telepon"),
                          subtitle: Text(
                            hpController.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              showEditDialog(
                                title: "Edit Nomor Telepon",
                                controller: hpController,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  infoTile(
                    icon: Icons.home_outlined,
                    title: "Nomor Rumah",
                    value: profil["no_rumah"]?.toString() ?? "-",
                  ),

                  infoTile(
                    icon: Icons.square_foot,
                    title: "Luas Tanah",
                    value: "${profil["luas_tanah"] ?? "-"} m²",
                  ),

                  infoTile(
                    icon: Icons.verified_user_outlined,
                    title: "Status",
                    value: profil["status"] ?? "-",
                  ),
                ],
              ),
            ),
    );
  }
}
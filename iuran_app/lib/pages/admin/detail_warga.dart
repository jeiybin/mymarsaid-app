import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'edit_warga.dart';
import 'package:iuran_app/api.dart';
class DetailWargaPage extends StatefulWidget {
  final Map data;
  final Function refreshParent; 

  DetailWargaPage({required this.data, required this.refreshParent});
  @override
  _DetailWargaPageState createState() => _DetailWargaPageState();
}

class _DetailWargaPageState extends State<DetailWargaPage> {
  late Map currentData;

  @override
  void initState() {
    super.initState();
    currentData = widget.data;
  }

  Future<void> fetchDetailWarga() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/warga/${currentData['id_warga']}",
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          currentData = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil Warga"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  currentData['nama'] != null ? currentData['nama'][0].toUpperCase() : "?",
                  style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(currentData['nama'] ?? '-', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  _buildListTile(Icons.home, "Nomor Rumah", currentData['no_rumah'] ?? '-'),
                  _buildListTile(Icons.landscape, "Luas Tanah", "${currentData['luas_tanah'] ?? '-'} m²"),
                  _buildListTile(Icons.phone, "Nomor HP", currentData['no_hp'] ?? '-'),
                  _buildListTile(Icons.info, "Status", (currentData['status'] ?? 'aktif').toUpperCase()),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditWarga(
                            data: currentData,
                            refreshParent: fetchDetailWarga,
                          ),
                        ),
                      );

                      if (result == true) {
                        await fetchDetailWarga();
                        widget.refreshParent();
                      }

                    },

                    icon: Icon(Icons.edit),
                    label: Text("Edit Profil"),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                    onPressed: () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Konfirmasi"),
                          content: Text("Yakin ingin menghapus data warga ${currentData['nama']}?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Batal")),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Hapus")),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          final response = await http.delete(
                            Uri.parse("${Api.baseUrl}/hapus_warga/${currentData['id_warga']}")
                          );

                          if (response.statusCode == 200) {
                            widget.refreshParent(); 
                            
                            Navigator.pop(context);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Data berhasil dihapus")),
                            );
                          } else {
                            throw Exception("Gagal menghapus");
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Terjadi kesalahan saat menghapus")),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.delete, color: Colors.white),
                    label: Text("Hapus", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
    );
  }
}
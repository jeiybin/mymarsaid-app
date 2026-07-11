import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InfoWarga extends StatefulWidget {
  final Map data;
  final Function refreshParent;

  InfoWarga({required this.data, required this.refreshParent});
  @override
  _InfoWargaState createState() => _InfoWargaState();
}

class _InfoWargaState extends State<InfoWarga> {
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
          "http://10.0.2.2:5000/warga/${currentData['id_warga']}",
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
                  currentData['nama'] != null
                      ? currentData['nama'][0].toUpperCase()
                      : "?",
                  style: TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(currentData['nama'] ?? '-',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  _buildListTile(Icons.home, "Nomor Rumah",
                      currentData['no_rumah'] ?? '-'),
                  Divider(),
                  _buildListTile(Icons.info, "Status",
                      (currentData['status'] ?? 'aktif').toUpperCase()),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
    );
  }
}

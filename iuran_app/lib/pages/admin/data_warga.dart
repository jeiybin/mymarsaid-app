import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'drawer_admin.dart';
import 'detail_warga.dart';
import 'add_warga.dart';
import 'package:iuran_app/api.dart';


class DataWarga extends StatefulWidget {
  @override
  State<DataWarga> createState() => _DataWargaState();
}

class _DataWargaState extends State<DataWarga> {
  List warga = [];
  List filteredWarga = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchWarga();
  }

  Future<void> fetchWarga() async {
    try {
      final response = await http.get(Uri.parse("${Api.baseUrl}/warga"));
      final data = jsonDecode(response.body);
      setState(() {
        warga = data;
        filteredWarga = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _runFilter(String keyword) {
    List results = warga.where((item) {
      final nama = item['nama'].toString().toLowerCase();
      final rumah = item['no_rumah'].toString().toLowerCase();
      return nama.contains(keyword.toLowerCase()) || rumah.contains(keyword.toLowerCase());
    }).toList();
    setState(() => filteredWarga = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Data Warga")),
      drawer: AppDrawer(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TambahWarga())).then((_) => fetchWarga()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                hintText: "Cari nama atau nomor rumah...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredWarga.isEmpty
                    ? Center(child: Text("Belum ada data warga"))
                    : ListView.builder(
                        itemCount: filteredWarga.length,
                        itemBuilder: (context, index) {
                          final item = filteredWarga[index];
                          final status = (item['status'] ?? 'aktif').toString().toLowerCase();

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(14),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  item['nama'] != null && item['nama'].isNotEmpty ? item['nama'][0].toUpperCase() : "?",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['nama'] ?? '-',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: status == 'aktif' ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Text("No Rumah : ${item['no_rumah'] ?? '-'}"),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailWargaPage(
                                      data: item,
                                      refreshParent: fetchWarga, 
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
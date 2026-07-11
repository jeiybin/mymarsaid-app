import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'detail_agenda.dart';
import 'drawer_admin.dart';
import 'package:iuran_app/api.dart';

class AgendaPage extends StatefulWidget {
  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  List agendaList = [];
  bool isLoading = true;
  String selectedYear = DateTime.now().year.toString();
  List<String> tahun = [];

  void dialogHapusAgenda(Map agenda) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Agenda"),
        content: Text(
          "Yakin ingin menghapus agenda '${agenda['nama']}'?\n\nSemua transaksi terkait juga akan ikut terhapus.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              final response = await http.post(
                Uri.parse(
                  "${Api.baseUrl}/hapus_agenda",
                ),
                body: {
                  "id_agenda": agenda['id_agenda'].toString(),
                },
              );

              Navigator.pop(context);

              if (response.statusCode == 200) {
                fetchAgenda();
              }
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    tahun = [
      (now.year - 1).toString(),
      now.year.toString(),
      (now.year + 1).toString(),
    ];

    fetchAgenda();
  }

  String formatDate(dynamic dateInput) {
    if (dateInput == null || dateInput.toString().isEmpty) return '-';

    String strDate = dateInput.toString();

    try {
      if (strDate.contains(',')) {
        List<String> parts = strDate.split(' ');
        String dd = parts[1];
        String mm = convertMonthToNumber(parts[2]);
        String yyyy = parts[3];
        return "$dd/$mm/$yyyy";
      } else if (strDate.length >= 10) {
        String yyyy = strDate.substring(0, 4);
        String mm = strDate.substring(5, 7);
        String dd = strDate.substring(8, 10);
        return "$dd/$mm/$yyyy";
      }
    } catch (e) {
      return strDate;
    }

    return strDate;
  }

  String convertMonthToNumber(String month) {
    switch (month.toLowerCase()) {
      case 'jan':
        return '01';
      case 'feb':
        return '02';
      case 'mar':
        return '03';
      case 'apr':
        return '04';
      case 'may':
        return '05';
      case 'jun':
        return '06';
      case 'jul':
        return '07';
      case 'aug':
        return '08';
      case 'sep':
        return '09';
      case 'oct':
        return '10';
      case 'nov':
        return '11';
      case 'dec':
        return '12';
      default:
        return '01';
    }
  }

  Future<void> fetchAgenda() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/agenda?tahun=$selectedYear",
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          agendaList = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void dialogTambahAgenda() {
    final namaController = TextEditingController();

    DateTime tglMulai = DateTime.now();
    DateTime tglBerakhir = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("Tambah Agenda"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: "Nama Agenda",
                  ),
                ),
                ListTile(
                  title: Text(
                    "Mulai: ${tglMulai.day}/${tglMulai.month}/${tglMulai.year}",
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tglMulai,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setModalState(() {
                        tglMulai = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    "Berakhir: ${tglBerakhir.day}/${tglBerakhir.month}/${tglBerakhir.year}",
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tglBerakhir,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setModalState(() {
                        tglBerakhir = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                await http.post(
                  Uri.parse("${Api.baseUrl}/add_agenda"),
                  headers: {
                    "Content-Type": "application/json",
                  },
                  body: jsonEncode({
                    "nama": namaController.text,
                    "tgl_mulai":
                        "${tglMulai.year}-${tglMulai.month.toString().padLeft(2, '0')}-${tglMulai.day.toString().padLeft(2, '0')}",
                    "tgl_berakhir":
                        "${tglBerakhir.year}-${tglBerakhir.month.toString().padLeft(2, '0')}-${tglBerakhir.day.toString().padLeft(2, '0')}",
                  }),
                );

                Navigator.pop(context);
                fetchAgenda();
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: const Text("Agenda Warga"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Tahun",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedYear,
                        items: tahun
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedYear = val!;
                          });

                          fetchAgenda();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: agendaList.length,
                    itemBuilder: (context, index) {
                      final item = agendaList[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          title: Text(
                            item['nama'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "${formatDate(item['tgl_mulai'])} - ${formatDate(item['tgl_berakhir'])}",
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'hapus') {
                                dialogHapusAgenda(item);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'hapus',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Hapus Agenda",
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailAgenda(
                                  agenda: item,
                                ),
                              ),
                            );

                            if (result == true) {
                              fetchAgenda();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: dialogTambahAgenda,
        child: const Icon(Icons.add),
      ),
    );
  }
}

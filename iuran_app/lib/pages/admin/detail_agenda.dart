import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';

import 'aksi_agenda.dart';

class DetailAgenda extends StatefulWidget {
  final Map agenda;
  DetailAgenda({required this.agenda});

  @override
  State<DetailAgenda> createState() => _DetailAgendaState();
}

class _DetailAgendaState extends State<DetailAgenda> {
  List transaksiList = [];
  List wargaList = [];
  bool isLoading = true;

  final List<String> kategoriMasuk = ['Donasi Warga', 'Sponsor', 'Lain-lain'];
  final List<String> kategoriKeluar = [
    'Perlengkapan Acara',
    'Hadiah',
    'Konsumsi',
    'Sewa Alat',
    'Transportasi',
    'Lain-lain'
  ];

  String filterMasuk = 'Semua';
  String filterKeluar = 'Semua';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final respTrx = await http.get(Uri.parse(
          "http://10.0.2.2:5000/transaksi?id_agenda=${widget.agenda['id_agenda']}"));
      final respWarga = await http.get(Uri.parse("http://10.0.2.2:5000/warga"));

      if (respTrx.statusCode == 200 && respWarga.statusCode == 200) {
        setState(() {
          transaksiList = jsonDecode(respTrx.body);
          wargaList = jsonDecode(respWarga.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  // FORMAT RUPIAH
  String formatRupiah(dynamic nominal) {
    if (nominal == null) return "Rp 0";
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(int.tryParse(nominal.toString()) ?? 0);
  }

// FORMAT TANGGAL
  String formatTanggal(dynamic tglInput) {
    if (tglInput == null || tglInput.toString().isEmpty) return '-';
    String tglStr = tglInput.toString();

    if (tglStr.contains('GMT')) {
      List<String> parts = tglStr.split(' ');
      if (parts.length >= 4) {
        return "${parts[1]} ${parts[2]} ${parts[3]}";
      }
    }

    try {
      DateTime parsed = DateTime.parse(tglStr);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (e) {
      return tglStr.split(' ')[0];
    }
  }

  // WIDGET REKAP
  Widget summaryCard(IconData icon, String title, String amount, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: Text(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalMasuk = 0;
    int totalKeluar = 0;

    for (var t in transaksiList) {
      int nominal = int.tryParse(t['nominal'].toString()) ?? 0;
      if (t['jenis'] == 'masuk') {
        totalMasuk += nominal;
      } else if (t['jenis'] == 'keluar') {
        totalKeluar += nominal;
      }
    }
    int saldoSisa = totalMasuk - totalKeluar;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.agenda['nama'] ?? 'Detail Agenda',
                  overflow: TextOverflow
                      .ellipsis, // Mencegah teks terlalu panjang menabrak icon
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: dialogEditAgenda,
              ),
            ],
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        summaryCard(Icons.trending_up, "Total Pemasukan",
                            formatRupiah(totalMasuk), Colors.green),
                        summaryCard(Icons.trending_down, "Total Pengeluaran",
                            formatRupiah(totalKeluar), Colors.red),
                        summaryCard(Icons.account_balance_wallet, "Saldo Sisa",
                            formatRupiah(saldoSisa), Colors.blue),
                      ],
                    ),
                  ),

                  // --- BAGIAN TENGAH: TAB BAR ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Theme.of(context).primaryColor,
                        tabs: const [
                          Tab(text: "Masuk"),
                          Tab(text: "Keluar"),
                        ],
                      ),
                    ),
                  ),

                  // --- BAGIAN BAWAH: LIST DATA ---
                  Expanded(
                    child: TabBarView(
                      children: [
                        buildList('masuk'),
                        buildList('keluar'),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => dialogTambahTransaksi(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget buildList(String jenis) {
    // 1. Tentukan list kategori
    List<String> listKategori = ['Semua'];
    if (jenis == 'masuk') {
      listKategori.addAll(kategoriMasuk);
    } else {
      listKategori.addAll(kategoriKeluar);
    }

    String filterAktif = (jenis == 'masuk') ? filterMasuk : filterKeluar;

    final filteredData = transaksiList.where((t) {
      bool matchJenis = t['jenis'] == jenis;
      bool matchKategori =
          (filterAktif == 'Semua') || (t['kategori'] == filterAktif);
      return matchJenis && matchKategori;
    }).toList();

    return Column(
      children: [
        // --- BARIS DROPDOWN FILTER ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: filterAktif,
                icon: const Icon(Icons.filter_list),
                onChanged: (String? newValue) {
                  setState(() {
                    if (jenis == 'masuk') {
                      filterMasuk = newValue!;
                    } else {
                      filterKeluar = newValue!;
                    }
                  });
                },
                items:
                    listKategori.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // --- DAFTAR TRANSAKSI ---
        Expanded(
          child: filteredData.isEmpty
              ? Center(child: Text("Belum ada data $filterAktif"))
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredData.length,
                  itemBuilder: (context, i) {
                    final item = filteredData[i];
                    final String? noRumah = item['no_rumah']?.toString();
                    final String? namaWarga = item['nama_warga']?.toString() ??
                        item['nama']?.toString();
                    final String ket = item['ket'] ?? '';
                    final String tgl = formatTanggal(item['tgl']);

                    String? teksWarga;
                    if (noRumah != null && namaWarga != null) {
                      teksWarga = "[$noRumah] $namaWarga";
                    } else if (namaWarga != null) {
                      teksWarga = namaWarga;
                    }

                    final Color nominalColor =
                        jenis == 'masuk' ? Colors.green : Colors.red;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => pilihAksiAgenda(item),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        title: Text(
                          item['kategori'] ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(teksWarga ?? '',
                                style: const TextStyle(fontSize: 14)),
                            Text(tgl,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                            if (ket.isNotEmpty)
                              Text(ket,
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600])),
                          ],
                        ),
                        trailing: Text(
                          formatRupiah(item['nominal']),
                          style: TextStyle(
                              color: nominalColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // MENU BAWAH SAAT CARD DIKLIK
  void pilihAksiAgenda(Map item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AksiAgendaPage(
          agenda: item, //
          refreshParent: () => fetchData(),
        ),
      ),
    );
  }

  void dialogTambahTransaksi() {
    String selectedJenis = 'masuk';
    String selectedKategori = kategoriMasuk[0];
    int? selectedWargaId;
    final nominalController = TextEditingController();
    final ketController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    final tglController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(selectedDate));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          title: const Text("Tambah Transaksi"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedJenis,
                  decoration: const InputDecoration(labelText: "Kategori"),
                  items: ['masuk', 'keluar']
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setModal(() {
                    selectedJenis = v!;
                    selectedKategori = (selectedJenis == 'masuk')
                        ? kategoriMasuk[0]
                        : kategoriKeluar[0];
                  }),
                ),
                if (selectedJenis == 'masuk')
                  DropdownSearch<Map<String, dynamic>>(
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration:
                            InputDecoration(labelText: "Cari Nama/No Rumah"),
                      ),
                    ),
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: const InputDecoration(
                        labelText: "Pilih Warga",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    items: (filter, loadProps) => wargaList
                        .map((w) => {
                              'id_warga': w['id_warga'],
                              'nama': "[${w['no_rumah'] ?? '-'}] ${w['nama']}"
                            })
                        .toList(),
                    compareFn: (item1, item2) =>
                        item1['id_warga'] == item2['id_warga'],
                    itemAsString: (item) => item['nama'],
                    onChanged: (v) =>
                        setModal(() => selectedWargaId = v?['id_warga']),
                  ),

                DropdownButtonFormField<String>(
                  value: selectedKategori,
                  decoration: const InputDecoration(labelText: "Jenis"),
                  items: (selectedJenis == 'masuk'
                          ? kategoriMasuk
                          : kategoriKeluar)
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (v) => setModal(() => selectedKategori = v!),
                ),

                // DATE PICKER FIELD
                TextFormField(
                  controller: tglController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Tanggal Transaksi",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setModal(() {
                        selectedDate = picked;
                        tglController.text =
                            DateFormat('yyyy-MM-dd').format(picked);
                      });
                    }
                  },
                ),

                TextField(
                  controller: nominalController,
                  decoration: const InputDecoration(labelText: "Nominal"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                    controller: ketController,
                    decoration: const InputDecoration(labelText: "Keterangan")),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                String nominalBersih = nominalController.text
                    .replaceAll('.', '')
                    .replaceAll(',', '');

                final url = Uri.parse("http://10.0.2.2:5000/add_transaksi");
                await http.post(url, body: {
                  'id_agenda': widget.agenda['id_agenda'].toString(),
                  'id_warga': selectedWargaId?.toString() ?? '',
                  'jenis': selectedJenis,
                  'kategori': selectedKategori,
                  'nominal': nominalBersih,
                  'ket': ketController.text,
                  'tgl': tglController.text, // MENGIRIM TANGGAL KE FLASK
                });
                Navigator.pop(context);
                fetchData();
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void dialogEditAgenda() {
    final namaController = TextEditingController(text: widget.agenda['nama']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Agenda"),
          content: TextFormField(
            controller: namaController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Nama Agenda",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final response = await http.post(
                  Uri.parse("http://10.0.2.2:5000/edit_agenda"),
                  body: {
                    "id_agenda": widget.agenda['id_agenda'].toString(),
                    "nama": namaController.text.trim(),
                  },
                );

                if (response.statusCode == 200) {
                  setState(() {
                    widget.agenda['nama'] = namaController.text.trim();
                  });

                  Navigator.of(context).pop();
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iuran_app/api.dart';
import 'detail_iuran.dart';

class KelolaIuran extends StatefulWidget {
  @override
  State<KelolaIuran> createState() => _KelolaIuranState();
}

class _KelolaIuranState extends State<KelolaIuran> {
  List warga = [];
  List filteredWarga = [];

  String selectedStatus = "Semua";

  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  String selectedYear = "";
  String selectedMonth = "";

  List<String> tahun = [];

  final List bulan = [
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember",
  ];

  // INIT
  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    selectedMonth = bulan[now.month - 1];

    selectedYear = now.year.toString();

    tahun = [
      (now.year - 2).toString(),
      (now.year - 1).toString(),
      now.year.toString(),
      (now.year + 1).toString(),
    ];

    fetchIuran();
  }

  // FETCH DATA IURAN
  Future<void> fetchIuran() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/kelola_iuran"
          "?bulan=$selectedMonth"
          "&tahun=$selectedYear"
          "&status=$selectedStatus",
        ),
      );

      final data = jsonDecode(response.body);

      setState(() {
        warga = data;

        filteredWarga = data;

        isLoading = false;
      });
    } catch (e) {
      print(e);

      setState(() {
        isLoading = false;
      });
    }
  }

  // SEARCH WARGA
  void searchWarga(String keyword) {
    final result = warga.where((item) {
      final nama = item['nama'].toString().toLowerCase();

      final rumah = item['no_rumah'].toString().toLowerCase();

      final input = keyword.toLowerCase();

      return nama.contains(input) || rumah.contains(input);
    }).toList();

    setState(() {
      filteredWarga = result;
    });
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kelola Iuran"),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SUMMARY
                  Row(
                    children: [
                      Expanded(
                        child: summaryCard(
                          "Total Warga",
                          "${warga.length}",
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: summaryCard(
                          "Bulan",
                          selectedMonth,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // FILTER BULAN
                  DropdownButtonFormField(
                    value: selectedMonth,
                    decoration: InputDecoration(
                      labelText: "Pilih Bulan",
                    ),
                    items: bulan.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value.toString();
                      });
                      fetchIuran();
                    },
                  ),

                  SizedBox(height: 15),

                  // FILTER TAHUN
                  DropdownButtonFormField(
                    value: selectedYear,
                    decoration: InputDecoration(
                      labelText: "Pilih Tahun",
                    ),
                    items: tahun.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value.toString();
                      });

                      fetchIuran();
                    },
                  ),

                  SizedBox(height: 20),

                  // SEARCH
                  TextField(
                    controller: searchController,
                    onChanged: searchWarga,
                    decoration: InputDecoration(
                      hintText: "Cari warga...",
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),

                  SizedBox(height: 20),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        buildFilterChip("Semua"),
                        const SizedBox(width: 10),
                        buildFilterChip("Belum Bayar"),
                        const SizedBox(width: 10),
                        buildFilterChip("Lunas"),
                      ],
                    ),
                  ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: filteredWarga.length,
                    itemBuilder: (context, index) {
                      final item = filteredWarga[index];

                      final status = item['status'] ?? 'Belum Bayar';

                      return Card(
                        margin: EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(14),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              item['nama'][0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            item['nama'] ?? '-',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              Text(
                                "Rumah ${item['no_rumah']}",
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: status == 'Lunas'
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailIuran(
                                  data: item,
                                  selectedMonth: selectedMonth,
                                  selectedYear: selectedYear,
                                ),
                              ),
                            );

                            if (result == true) {
                              fetchIuran();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildFilterChip(String status) {
    final selected = selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStatus = status;
        });

        fetchIuran();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color:
              selected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.transparent,
          ),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: selected
                ? Colors.white
                : const Color.fromARGB(255, 93, 127, 94),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // SUMMARY CARD
  Widget summaryCard(
    String title,
    String value,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

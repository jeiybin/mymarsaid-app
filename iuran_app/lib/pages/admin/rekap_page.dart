import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'detail_pemasukan.dart';
import 'detail_pengeluaran.dart';
import 'package:iuran_app/api.dart';

class RekapPage extends StatefulWidget {
  @override
  State<RekapPage> createState() => _RekapPageState();
}

class _RekapPageState extends State<RekapPage> {
  Map rekapData = {};

  bool isLoading = true;

  List<double> pemasukanChart = [];

  List<double> pengeluaranChart = [];

  List<String> bulanChart = [];

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

  String selectedMonth = "";

  String selectedYear = "";

  List<String> get tahun {
    int currentYear = DateTime.now().year;

    return [
      (currentYear - 1).toString(),
      currentYear.toString(),
      (currentYear + 1).toString(),
    ];
  }

  @override
  void initState() {
    super.initState();

    selectedMonth = bulan[DateTime.now().month - 1];

    selectedYear = DateTime.now().year.toString();

    fetchRekap();

    fetchGrafik();
  }

  Future<void> fetchRekap() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/rekap"
          "?bulan=$selectedMonth"
          "&tahun=$selectedYear",
        ),
      );

      print("STATUS:");
      print(response.statusCode);

      print("BODY:");
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          rekapData = data;
        });

        print(rekapData);
      }
    } catch (e) {
      print(
        "ERROR REKAP: $e",
      );
    }
  }

  Future<void> fetchGrafik() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/grafik_rekap"
          "?tahun=$selectedYear",
        ),
      );

      final data = jsonDecode(response.body);

      setState(() {
        bulanChart = List<String>.from(
          data.map(
            (e) => e["bulan"],
          ),
        );

        pemasukanChart = List<double>.from(
          data.map(
            (e) => double.parse(
              e["pemasukan"].toString(),
            ),
          ),
        );

        pengeluaranChart = List<double>.from(
          data.map(
            (e) => double.parse(
              e["pengeluaran"].toString(),
            ),
          ),
        );
        isLoading = false;
      });
    } catch (e) {
      print(
        "ERROR GRAFIK : $e",
      );
    }
  }

  String formatRupiah(num nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(nominal);
  }

  Widget summaryCard(
    IconData icon,
    String title,
    String value,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(
                  0.15,
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget grafikKeuangan() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Statistik Tahun $selectedYear",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                  ),
                  borderData: FlBorderData(
                    show: true,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (
                          value,
                          meta,
                        ) {
                          int index = value.toInt();

                          if (index < 0 || index >= bulanChart.length) {
                            return SizedBox();
                          }

                          return Padding(
                            padding: EdgeInsets.only(
                              top: 8,
                            ),
                            child: Text(
                              bulanChart[index],
                              style: TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(bulanChart.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: pemasukanChart.isNotEmpty
                              ? pemasukanChart[index]
                              : 0,
                          color: Colors.green,
                          width: 10,
                        ),
                        BarChartRodData(
                          toY: pengeluaranChart.isNotEmpty
                              ? pengeluaranChart[index]
                              : 0,
                          color: Colors.red,
                          width: 10,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.square,
                  color: Colors.green,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  "Pemasukan",
                ),
                SizedBox(width: 20),
                Icon(
                  Icons.square,
                  color: Colors.red,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  "Pengeluaran",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Rekap Keuangan",
        ),
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedMonth,
                          decoration: InputDecoration(
                            labelText: "Bulan",
                            border: OutlineInputBorder(),
                          ),
                          items: bulan.map((e) {
                            return DropdownMenuItem<String>(
                              value: e,
                              child: Text(
                                e,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMonth = value!;
                            });

                            fetchRekap();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedYear,
                          decoration: InputDecoration(
                            labelText: "Tahun",
                            border: OutlineInputBorder(),
                          ),
                          items: tahun.map((e) {
                            return DropdownMenuItem<String>(
                              value: e,
                              child: Text(
                                e,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedYear = value!;
                            });

                            fetchRekap();
                            fetchGrafik();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  grafikKeuangan(),
                  SizedBox(height: 20),
                  summaryCard(
                    Icons.trending_up,
                    "Pemasukan",
                    formatRupiah(
                      rekapData["pemasukan"] ?? 0,
                    ),
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailPemasukanPage(
                            bulan: selectedMonth,
                            tahun: selectedYear,
                          ),
                        ),
                      );
                    },
                  ),
                  summaryCard(
                    Icons.trending_down,
                    "Pengeluaran",
                    formatRupiah(
                      rekapData["pengeluaran"] ?? 0,
                    ),
                    Colors.red,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailPengeluaranPage(
                            bulan: selectedMonth,
                            tahun: selectedYear,
                          ),
                        ),
                      );
                    },
                  ),
                  summaryCard(
                    Icons.account_balance_wallet,
                    "Saldo Kas",
                    formatRupiah(
                      rekapData["saldo"] ?? 0,
                    ),
                    Colors.blue,
                    null,
                  ),
                ],
              ),
            ),
    );
  }
}

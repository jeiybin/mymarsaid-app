import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RekapChart extends StatelessWidget {

  final List pemasukan;
  final List pengeluaran;

  const RekapChart({

    super.key,

    required this.pemasukan,

    required this.pengeluaran,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      height: 250,

      padding: EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [

          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
          )
        ],
      ),

      child: LineChart(

        LineChartData(

          gridData: FlGridData(
            show: true,
          ),

          borderData: FlBorderData(
            show: false,
          ),

          lineBarsData: [

            // PEMASUKAN
            LineChartBarData(

              spots: List.generate(

                pemasukan.length,

                (index) => FlSpot(
                  index.toDouble(),
                  pemasukan[index]
                      .toDouble(),
                ),
              ),

              isCurved: true,

              color: Colors.green,

              barWidth: 4,
            ),

            // PENGELUARAN
            LineChartBarData(

              spots: List.generate(

                pengeluaran.length,

                (index) => FlSpot(
                  index.toDouble(),
                  pengeluaran[index]
                      .toDouble(),
                ),
              ),

              isCurved: true,

              color: Colors.red,

              barWidth: 4,
            ),
          ],
        ),
      ),
    );
  }
}
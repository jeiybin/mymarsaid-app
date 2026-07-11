import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailPengumumanWarga extends StatelessWidget {
  final Map pengumuman;

  const DetailPengumumanWarga({super.key, required this.pengumuman});

  String formatTanggal() {
    try {
      return DateFormat("dd MMMM yyyy, HH:mm", "id_ID")
              .format(DateTime.parse(pengumuman["tgl"])) +
          " WIB";
    } catch (_) {
      return pengumuman["tgl"] ?? "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Pengumuman")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.campaign,size:45,color: Colors.white),
            ),
            const SizedBox(height:16),
            Text(
              pengumuman["judul"] ?? "-",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize:22,fontWeight: FontWeight.bold),
            ),
            const SizedBox(height:8),
            Text(formatTanggal(),style: const TextStyle(color: Colors.grey,fontSize:13)),
            const SizedBox(height:24),
            Card(
              elevation:4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children:[
                        Icon(Icons.article_outlined,color: Colors.blueGrey),
                        SizedBox(width:8),
                        Text("Pengumuman !",style: TextStyle(fontWeight: FontWeight.bold,fontSize:16))
                      ],
                    ),
                    const Divider(height:25),
                    Text(
                      pengumuman["isi"] ?? "-",
                      style: const TextStyle(fontSize:16,height:1.6),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

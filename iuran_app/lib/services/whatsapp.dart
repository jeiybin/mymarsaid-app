import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  static Future<void> chatPengurus(BuildContext context) async {
    final lanjut = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.chat,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text("Chat Pengurus"),
            ],
          ),
          content: const Text(
            "Anda akan diarahkan ke aplikasi WhatsApp untuk menghubungi pengurus.\n\nApakah Anda ingin melanjutkan?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Lanjutkan"),
            ),
          ],
        );
      },
    );

    if (lanjut != true) return;

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:5000/pengurus"),
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data pengurus tidak ditemukan"),
          ),
        );
        return;
      }

      final data = jsonDecode(response.body);
      final String nomor = data["no_hp"];

      final Uri url = Uri.parse(
        "https://wa.me/$nomor?text=Halo,%20saya%20ingin%20menanyakan%20terkait%20iuran.%20Mohon%20bantuannya.%20Terima%20kasih.",
      );

      final berhasil = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!berhasil) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal membuka WhatsApp"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terjadi kesalahan"),
        ),
      );

      debugPrint(e.toString());
    }
  }
}
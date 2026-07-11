import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PengaturanPage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged; // Callback untuk update tema instan

  PengaturanPage({required this.onThemeChanged});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  bool isDarkMode = false;
  String selectedLanguage = 'Indonesia';

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  // Load pengaturan dari HP pengguna
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      selectedLanguage = prefs.getString('language') ?? 'Indonesia';
    });
  }

  // Simpan pengaturan ke HP pengguna
  Future<void> saveSettings(bool dark, String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', dark);
    await prefs.setString('language', lang);
    
    widget.onThemeChanged(dark ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: isDarkMode,
            onChanged: (val) {
              setState(() => isDarkMode = val);
              saveSettings(isDarkMode, selectedLanguage);
            },
          ),
          ListTile(
            title: const Text("Bahasa"),
            trailing: DropdownButton<String>(
              value: selectedLanguage,
              items: ['Indonesia', 'English'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (val) {
                setState(() => selectedLanguage = val!);
                saveSettings(isDarkMode, selectedLanguage);
              },
            ),
          ),
        ],
      ),
    );
  }
}
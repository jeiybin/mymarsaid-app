import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class AksiPengeluaranPage extends StatefulWidget {
  final Map item;
  final Function refreshParent;

  AksiPengeluaranPage({
    required this.item,
    required this.refreshParent,
  });

  @override
  State<AksiPengeluaranPage> createState() =>
      _AksiPengeluaranPageState();
}

class _AksiPengeluaranPageState
    extends State<AksiPengeluaranPage> {
  String? get currentId =>
      widget.item['id_pengeluaran']
          ?.toString() ??
      widget.item['id']
          ?.toString();

  String formatRupiah(
      dynamic nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(
      int.tryParse(
            nominal.toString(),
          ) ??
          0,
    );
  }

  void tampilkanFormEdit() {
    if (currentId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Error: ID tidak ditemukan!",
          ),
        ),
      );
      return;
    }

    final jenisController =
        TextEditingController(
      text:
          widget.item['jenis'] ??
              '',
    );

    final nominalController =
        TextEditingController(
      text:
          widget.item['nominal']
              .toString(),
    );

    final keteranganController =
        TextEditingController(
      text:
          widget.item[
                  'keterangan'] ??
              '',
    );

    DateTime selectedDate =
        DateTime.tryParse(
              widget.item[
                      'tanggal'] ??
                  '',
            ) ??
            DateTime.now();

    showDialog(
      context: context,
      builder: (_) =>
          StatefulBuilder(
        builder: (
          context,
          setModalState,
        ) {
          return AlertDialog(
            title: const Text(
              "Edit Pengeluaran",
            ),
            content:
                SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [

                  TextField(
                    controller:
                        jenisController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Jenis",
                    ),
                  ),

                  TextField(
                    controller:
                        nominalController,
                    keyboardType:
                        TextInputType
                            .number,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Nominal",
                    ),
                  ),

                  TextField(
                    controller:
                        keteranganController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Keterangan",
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    leading:
                        const Icon(
                      Icons
                          .calendar_month,
                    ),
                    title: Text(
                      DateFormat(
                        'dd MMMM yyyy',
                        'id_ID',
                      ).format(
                        selectedDate,
                      ),
                    ),
                    onTap:
                        () async {
                      final picked =
                          await showDatePicker(
                        context:
                            context,
                        initialDate:
                            selectedDate,
                        firstDate:
                            DateTime(
                                2020),
                        lastDate:
                            DateTime(
                                2100),
                      );

                      if (picked !=
                          null) {
                        setModalState(
                          () {
                            selectedDate =
                                picked;
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [

              TextButton(
                onPressed:
                    () =>
                        Navigator.pop(
                            context),
                child:
                    const Text(
                  "Batal",
                ),
              ),

              ElevatedButton(
                onPressed:
                    () async {
                  try {
                    final response =
                        await http
                            .post(
                      Uri.parse(
                        "http://10.0.2.2:5000/edit_pengeluaran/$currentId",
                      ),
                      headers: {
                        "Content-Type":
                            "application/json"
                      },
                      body:
                          jsonEncode({

                        "jenis":
                            jenisController
                                .text,

                        "nominal":
                            int.tryParse(
                                  nominalController
                                      .text,
                                ) ??
                                0,

                        "keterangan":
                            keteranganController
                                .text,

                        "tanggal":
                            DateFormat(
                          'yyyy-MM-dd',
                        ).format(
                          selectedDate,
                        ),
                      }),
                    );

                    if (response
                            .statusCode ==
                        200) {
                      widget
                          .refreshParent();

                      Navigator.pop(
                          context);

                      Navigator.pop(
                          context);

                      ScaffoldMessenger
                              .of(
                                  context)
                          .showSnackBar(
                        const SnackBar(
                          content:
                              Text(
                            "Berhasil diupdate",
                          ),
                        ),
                      );
                    } else {
                      print(
                        response.body,
                      );
                    }
                  } catch (e) {
                    print(e);
                  }
                },
                child:
                    const Text(
                  "Simpan",
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Detail Pengeluaran",
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(
                16),
        child: Column(
          children: [

            Card(
              elevation: 3,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                            16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(
                            20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [

                    _buildInfoRow(
                      Icons
                          .category_outlined,
                      "Jenis",
                      widget.item[
                              'jenis'] ??
                          '-',
                    ),

                    _buildInfoRow(
                      Icons
                          .description_outlined,
                      "Keterangan",
                      widget.item[
                              'keterangan'] ??
                          '-',
                    ),

                    _buildInfoRow(
                      Icons
                          .calendar_today,
                      "Tanggal",
                      widget.item[
                              'tanggal'] ??
                          '-',
                    ),

                    const Divider(
                      height:
                          30,
                    ),

                    const Text(
                      "Nominal",
                      style:
                          TextStyle(
                        fontSize:
                            14,
                        color: Colors
                            .grey,
                      ),
                    ),

                    Text(
                      formatRupiah(
                        widget.item[
                            'nominal'],
                      ),
                      style:
                          const TextStyle(
                        fontSize:
                            28,
                        fontWeight:
                            FontWeight
                                .bold,
                        color: Colors
                            .red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            OutlinedButton.icon(
              icon:
                  const Icon(
                Icons.edit,
              ),
              label:
                  const Text(
                "Edit Data",
              ),
              onPressed:
                  tampilkanFormEdit,
              style:
                  OutlinedButton
                      .styleFrom(
                minimumSize:
                    const Size(
                  double.infinity,
                  55,
                ),
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            ElevatedButton.icon(
              icon:
                  const Icon(
                Icons.delete,
                color:
                    Colors.white,
              ),
              label:
                  const Text(
                "Hapus Data",
                style:
                    TextStyle(
                  color: Colors
                      .white,
                ),
              ),
              onPressed:
                  () async {
                if (currentId ==
                    null)
                  return;

                bool? confirm =
                    await showDialog(
                  context:
                      context,
                  builder:
                      (_) =>
                          AlertDialog(
                    title:
                        const Text(
                      "Hapus",
                    ),
                    content:
                        const Text(
                      "Yakin ingin menghapus?",
                    ),
                    actions: [

                      TextButton(
                        onPressed:
                            () =>
                                Navigator.pop(
                                    context),
                        child:
                            const Text(
                          "Batal",
                        ),
                      ),

                      ElevatedButton(
                        onPressed:
                            () =>
                                Navigator.pop(
                                  context,
                                  true,
                                ),
                        child:
                            const Text(
                          "Hapus",
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm ==
                    true) {
                  final response =
                      await http
                          .delete(
                    Uri.parse(
                      "http://10.0.2.2:5000/hapus_pengeluaran/$currentId",
                    ),
                  );

                  if (response
                          .statusCode ==
                      200) {
                    widget
                        .refreshParent();

                    Navigator.pop(
                        context);
                  }
                }
              },
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    Colors.red,
                minimumSize:
                    const Size(
                  double.infinity,
                  55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [

          Icon(
            icon,
            size: 20,
            color:
                Colors.grey,
          ),

          const SizedBox(
            width: 10,
          ),

          SizedBox(
            width: 100,
            child: Text(
              label,
              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ),

          const Text(": "),

          Expanded(
            child:
                Text(value),
          ),
        ],
      ),
    );
  }
}
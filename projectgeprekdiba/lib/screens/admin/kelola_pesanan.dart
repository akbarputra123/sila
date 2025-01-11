import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Untuk decode JSON
import 'package:projectgeprekdiba/color.dart';
import 'dart:io'; // Import untuk menangani file lokal

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kelola Pesanan',
      theme: ThemeData(
        primarySwatch: myCustomColor,
        scaffoldBackgroundColor: Colors.black, // Background hitam
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white), // Teks putih
        ),
      ),
      home: KelolaPesananPage(),
    );
  }
}

class KelolaPesananPage extends StatefulWidget {
  const KelolaPesananPage({super.key});

  @override
  _KelolaPesananPageState createState() => _KelolaPesananPageState();
}

class _KelolaPesananPageState extends State<KelolaPesananPage> {
  List<Pesanan> pesananList = [];
  final Map<String, int> statusOrder = {
    'Diproses': 0,
    'Dikirim': 1,
    'Diterima': 2,
    'Selesai': 3,
  };

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final response = await http.get(
      Uri.parse(
          'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/orders.json'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      // Menambahkan log data yang diterima
      print("Data yang diterima: $data");

      List<Pesanan> loadedPesanan = [];
      data.forEach((key, value) {
        if (value['items'] != null) {
          List<dynamic> items = value['items'];
          for (var item in items) {
            loadedPesanan.add(Pesanan.fromJson(item, key)); // Tambahkan key di sini
          }
        }
      });

      setState(() {
        pesananList = loadedPesanan;
      });
    } else {
      throw Exception('Gagal mengambil data pesanan');
    }
  }

  Future<void> updateStatus(String key, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse(
            'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/orders/$key.json'),
        body: json.encode({
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        print("Status berhasil diperbarui: $newStatus");
      } else {
        print("Gagal memperbarui status. Kode: ${response.statusCode}");
      }
    } catch (error) {
      print("Terjadi kesalahan: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Urutkan pesanan berdasarkan status
    pesananList.sort(
        (a, b) => statusOrder[a.status]!.compareTo(statusOrder[b.status]!));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // hapus tombol kembali
        title: Text('Kelola Pesanan', style: TextStyle(color: Colors.white)),
        backgroundColor: myCustomColor,
      ),
      body: pesananList.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Menampilkan loading
          : ListView.builder(
              itemCount: pesananList.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(10),
                  color: Colors.grey[800], // Card background hitam
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Check if the image is a local file or an asset
                        File(pesananList[index].imagePath).existsSync()
                            ? Image.file(
                                File(pesananList[index].imagePath),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                pesananList[index].imagePath,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pesananList[index].name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Deskripsi: ${pesananList[index].description}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Harga: Rp ${pesananList[index].price}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Jumlah: ${pesananList[index].quantity}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Status: ${pesananList[index].status}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (status) async {
                            String key = pesananList[index].key; // Asumsikan setiap pesanan memiliki key
                            await updateStatus(key, status); // Memperbarui status di Firebase
                            setState(() {
                              pesananList[index].status = status;
                              pesananList.sort((a, b) =>
                                  statusOrder[a.status]!.compareTo(statusOrder[b.status]!));
                            });
                          },
                          icon: Icon(Icons.more_vert, color: myCustomColor),
                          itemBuilder: (context) {
                            return ['Diproses', 'Dikirim', 'Diterima', 'Selesai']
                                .map((status) => PopupMenuItem<String>(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class Pesanan {
  final String key; // Tambahkan key
  final String name;
  final String imagePath;
  final String description;
  String status;
  final int price;
  final int quantity;

  Pesanan({
    required this.key, // Tambahkan key sebagai parameter
    required this.name,
    required this.imagePath,
    required this.description,
    required this.status,
    required this.price,
    required this.quantity,
  });

  factory Pesanan.fromJson(Map<String, dynamic> json, String key) {
    return Pesanan(
      key: key, // Gunakan key dari Firebase
      name: json['name'] ?? 'Nama tidak tersedia',
      imagePath: json['imagePath'] ?? 'assets/default_image.png',
      description: json['description'] ?? 'Deskripsi tidak tersedia',
      status: json['status'] ?? 'Diproses',
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 1,
    );
  }
}

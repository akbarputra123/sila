import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Untuk decode JSON
import 'package:projectgeprekdiba/color.dart';

class HistoriPesananPage extends StatefulWidget {
  const HistoriPesananPage({super.key});

  @override
  _HistoriPesananPageState createState() => _HistoriPesananPageState();
}

class _HistoriPesananPageState extends State<HistoriPesananPage> {
  List<Pesanan> pesananList = [];
  String userId = '';

  @override
  void initState() {
    super.initState();
    fetchUserIdWithLatestLogin();
  }

  // Fungsi untuk mengambil ID pengguna dengan lastLogin terbaru
  Future<void> fetchUserIdWithLatestLogin() async {
  try {
    final response = await http.get(
      Uri.parse(
          'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/users.json'),
    );

    if (response.statusCode == 200) {
      print('Response body: ${response.body}'); // Debugging
      final Map<String, dynamic> data = json.decode(response.body);

      String latestUserId = '';
      DateTime latestLogin = DateTime(1970); // Set to a very old date initially

      data.forEach((userId, userData) {
        // Pastikan userData adalah Map sebelum mengaksesnya
        if (userData is Map<String, dynamic> && userData['lastLogin'] != null) {
          try {
            DateTime userLastLogin = DateTime.parse(userData['lastLogin']);
            if (userLastLogin.isAfter(latestLogin)) {
              latestLogin = userLastLogin;
              latestUserId = userId;
            }
          } catch (e) {
            print('Error parsing lastLogin for user $userId: $e');
          }
        } else {
          print('Invalid userData for user $userId: $userData');
        }
      });

      // Set the userId to the one with the latest login
      setState(() {
        userId = latestUserId;
      });

      // Setelah mendapatkan userId, ambil histori pesanan
      if (userId.isNotEmpty) {
        fetchHistoryOrders(userId);
      } else {
        print('Tidak ada user dengan lastLogin terbaru');
      }
    } else {
      throw Exception('Gagal mengambil data pengguna');
    }
  } catch (error) {
    print('Error saat mengambil data pengguna: $error');
  }
}


  // Fungsi untuk mengambil data histori pesanan berdasarkan userId
  Future<void> fetchHistoryOrders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/orders.json'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        List<Pesanan> loadedPesanan = [];
        data.forEach((key, value) {
          if (value['userId'] == userId && value['items'] != null) {
            List<dynamic> items = value['items'];
            for (var item in items) {
              // Gunakan nilai default jika status tidak ada
              String status = value['status'] ?? 'Tidak Diketahui';
              loadedPesanan.add(Pesanan.fromJson(item, status));
            }
          }
        });

        setState(() {
          pesananList = loadedPesanan;
        });
      } else {
        throw Exception('Gagal mengambil data histori pesanan');
      }
    } catch (error) {
      print('Error saat mengambil data histori pesanan: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // hapus tombol kembali
        title: const Text('Histori Pesanan', style: TextStyle(color: Colors.white)),
        backgroundColor: myCustomColor,
      ),
      body: pesananList.isEmpty
          ? Center(
              child: Text(
                'Belum ada pesanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ) // Menampilkan pesan jika data kosong
          : ListView.builder(
              itemCount: pesananList.length,
              itemBuilder: (context, index) {
                return PesananItem(
                  title: pesananList[index].name,
                  price: pesananList[index].price,
                  status: pesananList[index].status,
                );
              },
            ),
    );
  }
}

class PesananItem extends StatelessWidget {
  final String title;
  final int price;
  final String status;

  const PesananItem({
    super.key,
    required this.title,
    required this.price,
    required this.status,
  });

  // Fungsi untuk mendapatkan progress berdasarkan status
  double getProgress(String status) {
    switch (status) {
      case 'Diproses':
        return 0.3;
      case 'Dikirim':
        return 0.6;
      case 'Diterima':
        return 0.9;
      case 'Selesai':
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = getProgress(status);

    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text('Harga: Rp $price'),
            const SizedBox(height: 5),
            Text(
              status,
              style: TextStyle(
                color: myCustomColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: myCustomColor,
            ),
          ],
        ),
      ),
    );
  }
}

class Pesanan {
  final String name;
  final int price;
  final String status;

  Pesanan({
    required this.name,
    required this.price,
    required this.status,
  });

  factory Pesanan.fromJson(Map<String, dynamic> json, String? status) {
    return Pesanan(
      name: json['name'] ?? 'Nama tidak tersedia', // Nilai default jika null
      price: json['price'] ?? 0, // Harga default jika null
      status: status ?? 'Tidak Diketahui', // Nilai default untuk status
    );
  }
}

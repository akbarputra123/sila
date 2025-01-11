import 'package:flutter/material.dart';
import 'package:projectgeprekdiba/color.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Import this to use File for local images

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kelola Ulasan',
      theme: ThemeData(
        primarySwatch: myCustomColor,
        scaffoldBackgroundColor: Colors.black, // Background hitam
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white), // Teks putih
        ),
      ),
      home: KelolaUlasanPage(),
    );
  }
}

class KelolaUlasanPage extends StatefulWidget {
  const KelolaUlasanPage({super.key});

  @override
  _KelolaUlasanPageState createState() => _KelolaUlasanPageState();
}

class _KelolaUlasanPageState extends State<KelolaUlasanPage> {
  List<Ulasan> ulasanList = [];
  bool isLoading = true;
  Map<String, String> userNames = {}; // Menyimpan nama pengguna berdasarkan ID

  @override
  void initState() {
    super.initState();
    fetchUlasan();
    fetchUserNames(); // Mengambil data nama pengguna
  }

  // Fungsi untuk mengambil data nama pengguna berdasarkan userId
  Future<void> fetchUserNames() async {
    final url = Uri.parse(
        'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/users.json');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Log data yang diterima untuk nama pengguna
        print('Data Pengguna yang diterima: $data');

        // Menyimpan nama pengguna berdasarkan ID
        data.forEach((userId, userData) {
          setState(() {
            userNames[userId] = userData['name'] ?? 'Unknown'; // Mengambil 'name' dari data pengguna
          });
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (error) {
      print('Error fetching users: $error');
    }
  }

  // Fungsi untuk mengambil data ulasan
  Future<void> fetchUlasan() async {
    final url = Uri.parse(
        'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/reviews.json');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List<Ulasan> loadedUlasan = [];

        // Log data yang diterima untuk ulasan
        print('Data Ulasan yang diterima: $data');

        data.forEach((key, value) {
          loadedUlasan.add(Ulasan(
            key, // Gunakan key sebagai ID
            value['menu'] ?? 'Menu tidak diketahui',
            value['userId'] ?? 'Unknown', // Ambil userId dari data review
            value['userImage'] ?? 'assets/default.jpg', // Default jika gambar tidak ada
            value['ulasan'] ?? '',
            value['rating'] != null ? value['rating'].toDouble() : 0.0, // Pastikan rating adalah double
          ));
        });

        setState(() {
          ulasanList = loadedUlasan;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load ulasan');
      }
    } catch (error) {
      print('Error fetching ulasan: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fungsi untuk menghapus ulasan dari server
  Future<void> _hapusUlasanDiServer(String id, int index) async {
    final url = Uri.parse(
        'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/reviews/$id.json');

    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() {
          ulasanList.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ulasan berhasil dihapus')),
        );
      } else {
        throw Exception('Gagal menghapus ulasan di server');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  // Fungsi untuk menghapus ulasan (dengan konfirmasi)
  void _hapusUlasan(String id, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin menghapus ulasan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _hapusUlasanDiServer(id, index);
            },
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // hapus tombol kembali
        title: Text('Kelola Ulasan', style: TextStyle(color: Colors.white)),
        backgroundColor: myCustomColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: myCustomColor))
          : ulasanList.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada ulasan',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: ulasanList.length,
                  itemBuilder: (context, index) {
                    // Menampilkan nama pengguna berdasarkan userId
                    String userName = userNames[ulasanList[index].userId] ?? 'Unknown';

                    return Card(
                      margin: EdgeInsets.all(10),
                      color: Colors.grey[800], // Card background abu
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                           
                               
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName, // Menampilkan nama pengguna
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Ulasan: ${ulasanList[index].content}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Rating: ${ulasanList[index].rating} ★',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.delete, color: myCustomColor),
                              onPressed: () => _hapusUlasan(
                                ulasanList[index].id, // ID ulasan
                                index,
                              ),
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

class Ulasan {
  final String id; // Menambahkan ID
  final String dishName;
  final String userId; // Menambahkan ID pengguna
  final String userImage;
  final String content;
  final double rating; // Ubah rating menjadi double

  Ulasan(
      this.id, this.dishName, this.userId, this.userImage, this.content, this.rating);
}
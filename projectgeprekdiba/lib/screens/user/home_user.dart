import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectgeprekdiba/color.dart';

import 'menu_page.dart';
import 'histori_pesanan.dart';
import 'beri_ulasan.dart';
import 'profil_user.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HomeUser',
      home: HomePageUser(),
    );
  }
}

class HomePageUser extends StatefulWidget {
  const HomePageUser({super.key});

  @override
  _HomePageUserState createState() => _HomePageUserState();
}

class _HomePageUserState extends State<HomePageUser> {
  int _selectedIndex = 0;

  // Daftar pilihan untuk halaman
  static final List<Widget> _widgetOptions = <Widget>[
    KelolaBerandaUserPage(),
    MenuPage(),
    HistoriPesananPage(),
    BeriUlasanPage(),
    ProfilUserPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Histori Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review),
            label: 'Beri Ulasan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: myCustomColor,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}

class KelolaBerandaUserPage extends StatefulWidget {
  const KelolaBerandaUserPage({super.key});

  @override
  _KelolaBerandaUserPageState createState() => _KelolaBerandaUserPageState();
}

class _KelolaBerandaUserPageState extends State<KelolaBerandaUserPage> {
  String _userName = "User"; // Default value
  final String _url =
      'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/users.json';

  @override
  void initState() {
    super.initState();
    _fetchLatestUser();
  }

  Future<void> _fetchLatestUser() async {
    try {
      final response = await http.get(Uri.parse(_url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        String latestUserName = "User";
        DateTime? latestLoginTime;

        data.forEach((key, value) {
          if (value['lastLogin'] != null) {
            DateTime userLoginTime = DateTime.parse(value['lastLogin']);
            if (latestLoginTime == null || userLoginTime.isAfter(latestLoginTime!)) {
              latestLoginTime = userLoginTime;
              latestUserName = value['name'];
            }
          }
        });

        setState(() {
          _userName = latestUserName;
        });
      } else {
        throw Exception("Gagal mengambil data pengguna.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // hapus tombol kembali
        title: const Text('Beranda', style: TextStyle(color: Colors.white)),
        backgroundColor: myCustomColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Halo, $_userName.',
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
            Row(
              children: [
                Text(
                  '  Selamat Datang di Aplikasi Penjualan Ayam Geprek Diba!',
                  style: TextStyle(fontSize: 20, color: myCustomColor[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

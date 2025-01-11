import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectgeprekdiba/color.dart';
import 'package:projectgeprekdiba/screens/login_screen.dart';
import 'package:projectgeprekdiba/screens/user/editprofil.dart';

class ProfilUserPage extends StatefulWidget {
  const ProfilUserPage({super.key});

  @override
  _ProfilUserPageState createState() => _ProfilUserPageState();
}

class _ProfilUserPageState extends State<ProfilUserPage> {
  String _userName = 'User Name';
  String _userPassword = 'User Password';
  String _userProfileImage = ''; // Menyimpan path gambar lokal
  final String _defaultProfileImage = 'assets/default_profile.png';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

 Future<void> _fetchUserData() async {
  final url = Uri.parse(
      'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/users.json');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      print('Response body: ${response.body}'); // Debugging: Periksa respons
      final Map<String, dynamic> data = json.decode(response.body);

      // Variabel untuk menyimpan user dengan `lastLogin` terbaru
      String? latestUserKey;
      DateTime? latestLoginTime;

      // Iterasi data JSON
      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final lastLogin = DateTime.tryParse(value['lastLogin'] ?? '');
          if (lastLogin != null &&
              (latestLoginTime == null || lastLogin.isAfter(latestLoginTime!))) {
            latestLoginTime = lastLogin;
            latestUserKey = key;
          }
        } else {
          print('Invalid user data for key $key: $value');
        }
      });

      if (latestUserKey != null && data[latestUserKey] is Map<String, dynamic>) {
        final userData = data[latestUserKey] as Map<String, dynamic>;

        setState(() {
          _userName = userData['name'] ?? 'User Name';
          _userPassword = userData['password'] ?? 'User Password';
          _userProfileImage =
              userData['profileImage'] ?? ''; // Path gambar, bisa diubah
        });
      } else {
        print('Tidak ada user dengan lastLogin terbaru atau data tidak valid');
      }
    } else {
      print('Failed to fetch user data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching user data: $e');
  }
}

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => LoginPage()));
            },
            child: Text('Ya'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Profil User', style: TextStyle(color: Colors.white)),
          backgroundColor: myCustomColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Card(
                      color: myCustomColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 50.0),
                        child: Column(
                          children: [
                            SizedBox(height: 50),
                            Text(
                              _userName,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            SizedBox(height: 3),
                            Text(
                              _userPassword,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                   
                  ],
                ),
                SizedBox(height: 30),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfil(userId: '',

                      )));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: myCustomColor),
                    child: Text('Edit Profil', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(backgroundColor: myCustomColor),
                    child: Text('Logout', style: TextStyle(color: Colors.white)),
                  ),
                ]),
              ],
            ),
          ),
        ));
  }
}

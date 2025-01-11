import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectgeprekdiba/color.dart';

class EditProfil extends StatefulWidget {
  final String userId; // ID pengguna yang akan diubah datanya

  EditProfil({required this.userId});

  @override
  _EditProfilState createState() => _EditProfilState();
}

class _EditProfilState extends State<EditProfil> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _updateProfile() async {
    final updatedData = {
      'name': _nameController.text,
      'password': _passwordController.text,
      'lastLogin': DateTime.now().toIso8601String(), // Update lastLogin
    };

    final url = Uri.parse(
        'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/users/${widget.userId}.json');

    try {
      final response = await http.patch(url, body: json.encode(updatedData));

      if (response.statusCode == 200) {
        // Jika update berhasil, kembali ke halaman sebelumnya
        Navigator.pop(context);
      } else {
        print('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Edit Profil', style: TextStyle(color: Colors.white)),
       backgroundColor: myCustomColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nama'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(backgroundColor: myCustomColor,),
              child: Text('Simpan Perubahan', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Kembali ke halaman sebelumnya
              },
              style: ElevatedButton.styleFrom(backgroundColor: myCustomColor,),
              child: Text('Kembali ke Profil', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

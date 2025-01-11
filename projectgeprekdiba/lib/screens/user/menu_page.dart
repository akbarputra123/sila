import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Untuk decode JSON
import 'package:projectgeprekdiba/color.dart';
import 'dart:io';  // Import untuk bekerja dengan file lokal

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}
class _MenuPageState extends State<MenuPage> {
  // Change from Map<String, bool> to Map<String, int> to store quantities
  final Map<String, int> _selectedItems = {}; 
  List<MenuItemData> _menuItems = [];

  @override
  void initState() {
    super.initState();
    fetchMenuData();
  }

  Future<void> fetchMenuData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/menu.json'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        List<MenuItemData> loadedMenuItems = [];
        data.forEach((key, value) {
          loadedMenuItems.add(MenuItemData.fromJson(value));
        });
        
        setState(() {
          _menuItems = loadedMenuItems;
        });
      } else {
        throw Exception('Gagal memuat data menu');
      }
    } catch (e) {
      print('Error mengambil data menu: $e');
    }
  }

 Future<void> placeOrder() async {
  final selectedItems = _selectedItems.entries
      .where((entry) => entry.value > 0)  // Only select items with quantity > 0
      .map((entry) => entry.key)
      .toList();

  if (selectedItems.isEmpty) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pesanan Kosong'),
          content: const Text('Anda belum memilih menu untuk dipesan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return;
  }

  // Langkah 1: Ambil data pengguna dengan lastLogin terbaru
  String userId = await getUserWithLatestLogin();

  // Cek apakah userId ditemukan
  if (userId.isEmpty) {
    print('Error: Tidak ada user ID yang ditemukan');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ID Pengguna Tidak Ditemukan'),
          content: const Text('Tidak dapat menemukan ID pengguna dengan lastLogin terbaru.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return;
  }

  // Log ID pengguna yang ditemukan
  print('User ID ditemukan: $userId');

  // Langkah 2: Prepare order data to send to Firebase
  final List<Map<String, dynamic>> orderItems = selectedItems.map((itemTitle) {
    final menuItem = _menuItems.firstWhere((menuItem) => menuItem.title == itemTitle);
    
    // Get the quantity of the selected item
    int quantity = _selectedItems[itemTitle] ?? 1;

    return {
      'name': menuItem.title,
      'imagePath': menuItem.image,
      'description': menuItem.description,
      'price': menuItem.price,
      'quantity': quantity,  // Quantity of the item
    };
  }).toList();

  final Map<String, dynamic> orderData = {
    'userId': userId,  // Menambahkan ID pengguna
    'items': orderItems,  
    'totalPrice': orderItems
        .map((item) => item['price'] * item['quantity'])
        .reduce((sum, price) => sum + price),
    'timestamp': DateTime.now().toIso8601String(),
  };

  // Log the data being sent to the server
  print('Order Data to Firebase: $orderData');

  try {
    // Sending the order data to Firebase Realtime Database using HTTP POST
    final response = await http.post(
      Uri.parse('https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/orders.json'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(orderData),
    );

    if (response.statusCode == 200) {
      // Order successfully sent
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pesanan Dikirim'),
            content: Text('Pesanan Anda berhasil dikirim:\n${selectedItems.join('\n')}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      throw Exception('Gagal mengirim pesanan ke Firebase');
    }
  } catch (e) {
    print('Error mengirim pesanan: $e');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gagal Mengirim Pesanan'),
          content: const Text('Terjadi kesalahan saat mengirim pesanan. Coba lagi nanti.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// Fungsi untuk mengambil user dengan lastLogin terbaru
Future<String> getUserWithLatestLogin() async {
  try {
    final response = await http.get(Uri.parse(
        'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/users.json'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> usersData = json.decode(response.body);

      String latestUserId = '';
      DateTime latestLogin = DateTime(1970);  // Set to a very old date initially

      usersData.forEach((userId, userData) {
        // Pastikan lastLogin ada dan dalam format yang benar
        if (userData['lastLogin'] != null) {
          try {
            DateTime userLastLogin = DateTime.parse(userData['lastLogin']);
            
            // Check if this user's lastLogin is the latest
            if (userLastLogin.isAfter(latestLogin)) {
              latestLogin = userLastLogin;
              latestUserId = userId;
            }
          } catch (e) {
            print('Error parsing lastLogin for user $userId: $e');
          }
        }
      });

      // Log ID pengguna yang ditemukan
      if (latestUserId.isNotEmpty) {
        print('User ID dengan lastLogin terbaru: $latestUserId');
      } else {
        print('Tidak ada user dengan lastLogin ditemukan');
      }

      return latestUserId;
    } else {
      throw Exception('Gagal mengambil data pengguna');
    }
  } catch (e) {
    print('Error mengambil data pengguna: $e');
    return '';  // Return an empty string if there is an error
  }
}



 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Daftar Menu', style: TextStyle(color: Colors.white)),
      backgroundColor: myCustomColor,
    ),
    body: _menuItems.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
              return MenuItem(
                image: item.image,
                title: item.title,
                description: item.description,
                price: item.price,
                isSelected: (_selectedItems[item.title] ?? 0) > 0,  // Checks if quantity > 0
                quantity: _selectedItems[item.title] ?? 0,  // Provide the current quantity
                onChanged: (isSelected) {
                  setState(() {
                    // Update quantity: If selected, set to 1; if not, set to 0
                    _selectedItems[item.title] = (isSelected ?? false) ? 1 : 0;
                  });
                },
                onQuantityChanged: (newQuantity) {
                  setState(() {
                    _selectedItems[item.title] = newQuantity;  // Update quantity
                  });
                },
              );
            },
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: placeOrder,
      label: const Text('Pesan'),
      icon: const Icon(Icons.shopping_cart),
    ),
  );
}
}


class MenuItemData {
  final String title;
  final String description;
  final String image;
  final int price;

  MenuItemData({
    required this.title,
    required this.description,
    required this.image,
    required this.price,
  });

  factory MenuItemData.fromJson(Map<String, dynamic> json) {
    return MenuItemData(
      title: json['name'],
      description: json['description'],
      image: json['imagePath'],
      price: json['price'],
    );
  }
}

class MenuItem extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final int price;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final int quantity;  // Add quantity to the MenuItem widget
  final ValueChanged<int> onQuantityChanged;  // Callback to handle quantity change

  const MenuItem({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.isSelected,
    required this.onChanged,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(15),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: SizedBox(
          width: 80,
          height: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image.startsWith('/data/') 
                ? Image.file(File(image), fit: BoxFit.cover) // Use Image.file for local file path
                : Image(
                    image: image.startsWith('http') 
                        ? NetworkImage(image)  // For remote images
                        : AssetImage(image) as ImageProvider, // For assets
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rp $price',
              style: const TextStyle(
                color: Color(0xFFFF7417),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 10),
            Checkbox(
              value: isSelected,
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => onQuantityChanged(quantity + 1), // Increase quantity
                ),
                Text('$quantity'),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: quantity > 0 ? () => onQuantityChanged(quantity - 1) : null, // Decrease quantity
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          onChanged(!isSelected);
        },
      ),
    );
  }
}


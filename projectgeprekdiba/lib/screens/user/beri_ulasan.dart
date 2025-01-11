import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:projectgeprekdiba/color.dart';

class BeriUlasanPage extends StatefulWidget {
  const BeriUlasanPage({super.key});

  @override
  _BeriUlasanPageState createState() => _BeriUlasanPageState();
}

class _BeriUlasanPageState extends State<BeriUlasanPage> {
  double rating = 0;
  String userId = '';
  List<dynamic> userOrders = []; // List to store user orders
  Map<String, double> orderRatings = {}; // Store ratings for each order
  Map<String, String> orderUlasans = {}; // Store ulasans for each order
  Map<String, TextEditingController> ulasanControllers = {}; // Map for controllers
  Map<String, File> orderImages = {}; // Map to store images for orders

  @override
  void dispose() {
    // Dispose each controller in the map to avoid memory leaks
    ulasanControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

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
        final Map<String, dynamic> data = json.decode(response.body);

        String latestUserId = '';
        DateTime latestLogin =
            DateTime(1970); // Set to a very old date initially

        data.forEach((userId, userData) {
          if (userData['lastLogin'] != null) {
            try {
              DateTime userLastLogin = DateTime.parse(userData['lastLogin']);
              if (userLastLogin.isAfter(latestLogin)) {
                latestLogin = userLastLogin;
                latestUserId = userId;
              }
            } catch (e) {
              print('Error parsing lastLogin for user $userId: $e');
            }
          }
        });

        setState(() {
          userId = latestUserId;
        });

        if (userId.isNotEmpty) {
          fetchUserOrders(userId); // Fetch orders for the latest user
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

  // Fungsi untuk mengambil data pesanan berdasarkan userId
  Future<void> fetchUserOrders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/orders.json'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> orders = [];

        data.forEach((orderId, orderData) {
          if (orderData['userId'] == userId) {
            if (orderData['items'] != null && orderData['items'] is List) {
              for (var item in orderData['items']) {
                if (item is Map) {
                  if (item.containsKey('description') &&
                      item.containsKey('imagePath') &&
                      item.containsKey('name') &&
                      item.containsKey('price')) {
                    orders.add({
                      'name': item['name'] ?? 'Nama tidak tersedia',
                      'description': item['description'] ?? 'Deskripsi tidak tersedia',
                      'imagePath': item['imagePath'] ?? '',
                      'price': item['price'] ?? 0,
                      'orderId': orderId,
                    });
                    // Check if imagePath is a URL or a local file path
                    downloadImage(item['imagePath'], orderId);
                  }
                }
              }
            }
          }
        });

        setState(() {
          userOrders = orders;
        });
      } else {
        throw Exception('Gagal mengambil data pesanan');
      }
    } catch (error) {
      print('Error saat mengambil data pesanan: $error');
    }
  }

  // Fungsi untuk mengunduh gambar dan menyimpannya ke file lokal
  Future<void> downloadImage(String imagePath, String orderId) async {
    try {
      if (imagePath.isEmpty) {
        print("Image path is empty");
        return; // Handle empty path
      }

      if (imagePath.startsWith("http")) {
        // If it's a URL, download the image
        final response = await http.get(Uri.parse(imagePath));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$orderId.jpg');
          await file.writeAsBytes(bytes);

          setState(() {
            orderImages[orderId] = file; // Store the downloaded image file
          });
        } else {
          print('Failed to download image. Status: ${response.statusCode}');
        }
      } else {
        // If it's a local file path, use the File class directly
        final file = File(imagePath);
        if (await file.exists()) {
          setState(() {
            orderImages[orderId] = file; // Store the local image file
          });
        } else {
          print("Local file does not exist at $imagePath");
        }
      }
    } catch (e) {
      print('Error while downloading or loading image: $e');
    }
  }

  Future<void> kirimUlasan(String menu, String ulasan, int harga, double rating, String orderId, File? imageFile) async {
  // Convert the image to base64 if available
  String? base64Image;
  if (imageFile != null && imageFile.existsSync()) {
    List<int> imageBytes = await imageFile.readAsBytes();
    base64Image = base64Encode(imageBytes); // Convert to base64 string
  }

  final url = Uri.parse(
    'https://backendmobile-927b9-default-rtdb.asia-southeast1.firebasedatabase.app/reviews.json',
  );

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'menu': menu,
      'ulasan': ulasan,
      'harga': harga,
      'rating': rating,
      'userId': userId,
      'orderId': orderId,
      'timestamp': DateTime.now().toIso8601String(),
      'image': base64Image, // Sending the base64-encoded image
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print('Ulasan berhasil dikirim!');
  } else {
    print('Gagal mengirim ulasan: ${response.statusCode}');
    throw Exception('Gagal mengirim ulasan');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Beri Ulasan', style: TextStyle(color: Colors.white)),
        backgroundColor: myCustomColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userOrders.isNotEmpty) ...[
              Text(
                'Pesanan Terakhir:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: userOrders.length,
                itemBuilder: (context, index) {
                  final order = userOrders[index];
                  final orderId = order['orderId'];

                  // Membuat TextEditingController baru untuk setiap form ulasan
                  if (!ulasanControllers.containsKey(orderId)) {
                    ulasanControllers[orderId] = TextEditingController();
                  }

                  // Get the local image file for this order
                  final imageFile = orderImages[orderId];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Display local image if available
                            imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      imageFile,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : CircularProgressIndicator(), // Tampilkan progress jika gambar belum diunduh
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                order['name'],
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          order['description'],
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        RatingBar.builder(
                          initialRating: 0,
                          minRating: 1,
                          itemSize: 20,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4),
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            setState(() {
                              orderRatings[orderId] = rating;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: ulasanControllers[orderId],
                          decoration: InputDecoration(
                            labelText: 'Tulis Ulasan',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
  onPressed: () {
    String ulasan = ulasanControllers[orderId]!.text;
    double rating = orderRatings[orderId] ?? 0;
    File? imageFile = orderImages[orderId]; // Get the image file for this order
    kirimUlasan(order['name'], ulasan, order['price'], rating, orderId, imageFile);
  },
  child: Text('Kirim Ulasan'),
),

                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'logout.dart';
import 'edit_profile.dart';
import 'models/user.dart';
import 'db/db_helper.dart'; // Import DBHelper to get transaction counts
import 'order_history_page.dart'; // Import OrderHistoryPage


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  File? _avatarImage;
  int _orderHistoryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndCounts();
  }

  Future<void> _loadUserDataAndCounts() async {
    final prefs = await SharedPreferences.getInstance();
    String? emailPref = prefs.getString("email");
    if (emailPref == null) {
      debugPrint('ProfilePage: No email found in SharedPreferences.');
      setState(() {
        userData = null; // Explicitly set to null if no email, to show "User data not found" or similar
      });
      return;
    }

    debugPrint('ProfilePage: Loading user data for email: $emailPref');
    try {
      final User _user = User();
      final data = await _user.getUserByEmail(emailPref);
      debugPrint('ProfilePage: User data fetched: $data');

      final dbHelper = DBHelper();
      final userId = data?['user_id'];
      int orderCount = 0;
      if (userId != null) {
        final transactions = await dbHelper.getTransactionsByUserId(userId);
        orderCount = transactions.length;
        debugPrint('ProfilePage: Transactions count for user $userId: $orderCount');
      } else {
        debugPrint('ProfilePage: User ID is null, cannot fetch transactions.');
      }

      if (mounted) {
        setState(() {
          userData = data;
          _avatarImage = (userData?['avatar'] != null &&
                    userData!['avatar'].toString().isNotEmpty)
              ? File(userData!['avatar'])
              : null;
          _orderHistoryCount = orderCount;
        });
        debugPrint('ProfilePage: User data and counts updated in state.');
      }
    } catch (e) {
      debugPrint('ProfilePage: Error loading user data and counts: $e');
      if (mounted) {
        setState(() {
          userData = null; // Set to null on error to show appropriate message
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : buildProfileUI(),
    );
  }

  Widget buildProfileUI() {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _avatarImage != null
                          ? FileImage(_avatarImage!)
                          : null,
                      child: _avatarImage == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userData?["nama"] ?? "-",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Riwayat Pesanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  color: const Color(0xFFF2EDE5), // Set card background color to match fieldBox
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    // tileColor: const Color(0xFFF2EDE5), // Removed as Card color handles it
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF8D6E63), // Example color from image
                      child: Icon(Icons.receipt, color: Colors.white), // Example icon from image
                    ),
                    title: const Text('Riwayat Pesanan'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                fieldLabel("Name"),
                fieldBox(userData?["nama"] ?? ""),
                const SizedBox(height: 30),
                fieldLabel("Email"),
                fieldBox(userData?["email"] ?? ""),
                const SizedBox(height: 30),
                fieldLabel("Phone"),
                fieldBox(userData?["no_telp"] ?? ""),
                const SizedBox(height: 30),
                fieldLabel("Address"),
                fieldBox(userData?["alamat"] ?? ""),
                const SizedBox(height: 30),
                SizedBox(
                  width: 160,
                  height: 35,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D6E63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final updatedData = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfilePage(userData: userData!),
                        ),
                      );

                      if (updatedData != null) {
                        setState(() {
                          userData = updatedData;
                          _avatarImage = updatedData['avatar'] != null
                              ? File(updatedData['avatar'])
                              : null;
                        });
                      }
                    },
                    child: const Text(
                      "Edit Profile",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.black, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LogoutPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget fieldLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      );

  Widget fieldBox(String value) => TextField(
        readOnly: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF2EDE5),
          hintText: value,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
